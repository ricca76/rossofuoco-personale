package com.example

import android.Manifest
import android.app.DownloadManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Color as AndroidColor
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.URLUtil
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.example.ui.theme.MyApplicationTheme
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch

class MainActivity : FragmentActivity() {
  companion object {
    private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    enableEdgeToEdge()
    setContent {
      MyApplicationTheme {
        PortalWebViewApp(activity = this)
      }
    }
  }
}

fun observeConnectivity(context: Context): Flow<Boolean> = callbackFlow {
  val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

  val callback = object : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) {
      trySend(true)
    }

    override fun onLost(network: Network) {
      trySend(false)
    }

    override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
      val hasInternet = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
      trySend(hasInternet)
    }
  }

  val request = NetworkRequest.Builder()
    .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    .build()

  try {
    connectivityManager.registerNetworkCallback(request, callback)
  } catch (_: Exception) {}

  // Initial check
  val activeNetwork = connectivityManager.activeNetwork
  val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
  val isConnected = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
  trySend(isConnected)

  awaitClose {
    try {
      connectivityManager.unregisterNetworkCallback(callback)
    } catch (_: Exception) {}
  }
}

private fun launchBiometricAuth(
  activity: FragmentActivity,
  onSuccess: () -> Unit,
  onError: (String) -> Unit
) {
  val biometricManager = BiometricManager.from(activity)
  val authenticators = BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL
  val canAuth = biometricManager.canAuthenticate(authenticators)

  if (canAuth == BiometricManager.BIOMETRIC_SUCCESS) {
    val executor = ContextCompat.getMainExecutor(activity)
    val promptInfo = BiometricPrompt.PromptInfo.Builder()
      .setTitle("Autenticazione richiesta")
      .setSubtitle("RossoFuoco Personale")
      .setDescription("Usa l'impronta digitale, il riconoscimento facciale o il PIN per sbloccare l'app.")
      .setAllowedAuthenticators(authenticators)
      .build()

    val biometricPrompt = BiometricPrompt(
      activity,
      executor,
      object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
          super.onAuthenticationSucceeded(result)
          onSuccess()
        }

        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
          super.onAuthenticationError(errorCode, errString)
          onError(errString.toString())
        }

        override fun onAuthenticationFailed() {
          super.onAuthenticationFailed()
          onError("Impronta o volto non riconosciuto. Riprova.")
        }
      }
    )

    biometricPrompt.authenticate(promptInfo)
  } else {
    // Biometric hardware / credentials not available or not enrolled -> allow access directly
    onSuccess()
  }
}

private fun injectHybridBridge(webView: WebView?) {
  if (webView == null) return
  val js = """
    (function() {
      try {
        if (!window.RossoFuoco) {
          window.RossoFuoco = {
            notify: function(title, message) {
              if (window.AndroidBridge && window.AndroidBridge.postNotification) {
                window.AndroidBridge.postNotification(title || 'RossoFuoco', message || '');
              }
            },
            sync: function(dataType, data) {
              if (window.AndroidBridge && window.AndroidBridge.syncData) {
                var payload = (typeof data === 'string') ? data : JSON.stringify(data);
                window.AndroidBridge.syncData(dataType || 'generic', payload);
              }
            },
            toast: function(msg) {
              if (window.AndroidBridge && window.AndroidBridge.showToast) {
                window.AndroidBridge.showToast(msg);
              }
            },
            snackbar: function(msg) {
              if (window.AndroidBridge && window.AndroidBridge.showSnackbar) {
                window.AndroidBridge.showSnackbar(msg);
              }
            },
            getInfo: function() {
              if (window.AndroidBridge && window.AndroidBridge.getAppInfo) {
                try {
                  return JSON.parse(window.AndroidBridge.getAppInfo());
                } catch(e) {
                  return window.AndroidBridge.getAppInfo();
                }
              }
              return null;
            }
          };

          // Listen for custom web events dispatched by the portal
          window.addEventListener('rossofuoco:notify', function(e) {
            if (e && e.detail) {
              window.RossoFuoco.notify(e.detail.title || 'RossoFuoco', e.detail.message || '');
            }
          });

          window.addEventListener('rossofuoco:sync', function(e) {
            if (e && e.detail) {
              window.RossoFuoco.sync(e.detail.type || 'generic', e.detail.data || {});
            }
          });

          // Dispatch native ready event for web app
          var readyEvent = new CustomEvent('RossoFuocoNativeReady', { detail: window.RossoFuoco.getInfo() });
          window.dispatchEvent(readyEvent);
          document.dispatchEvent(readyEvent);
        }
      } catch(e) {}
    })();
  """.trimIndent()
  webView.evaluateJavascript(js, null)
}

private fun injectThemeMode(webView: WebView?, isDark: Boolean) {
  if (webView == null) return
  if (isDark) {
    val js = """
      (function() {
        try {
          document.documentElement.setAttribute('data-theme', 'dark');
          document.documentElement.setAttribute('data-bs-theme', 'dark');
          document.documentElement.classList.add('dark');
          if (document.body) {
            document.body.classList.add('dark');
          }
          var style = document.getElementById('app-dark-mode-override');
          if (!style) {
            style = document.createElement('style');
            style.id = 'app-dark-mode-override';
            style.innerHTML = `
              :root {
                color-scheme: dark !important;
                --bs-body-bg: #121212 !important;
                --bs-body-color: #e0e0e0 !important;
                --bs-dark-rgb: 18, 18, 18 !important;
                --bg-primary: #121212 !important;
                --text-primary: #e0e0e0 !important;
              }
              html, body {
                background-color: #121212 !important;
                color: #e0e0e0 !important;
              }
              .card, .panel, .modal-content, .bg-white, .table, header, nav, footer, .navbar {
                background-color: #1e1e1e !important;
                color: #e0e0e0 !important;
                border-color: #333333 !important;
              }
              input, select, textarea {
                background-color: #2a2a2a !important;
                color: #ffffff !important;
                border-color: #444444 !important;
              }
              a {
                color: #8ab4f8 !important;
              }
            `;
            (document.head || document.documentElement).appendChild(style);
          }
        } catch(e) {}
      })();
    """.trimIndent()
    webView.evaluateJavascript(js, null)
  } else {
    val js = """
      (function() {
        try {
          document.documentElement.removeAttribute('data-theme');
          document.documentElement.removeAttribute('data-bs-theme');
          document.documentElement.classList.remove('dark');
          if (document.body) {
            document.body.classList.remove('dark');
          }
          var style = document.getElementById('app-dark-mode-override');
          if (style && style.parentNode) {
            style.parentNode.removeChild(style);
          }
        } catch(e) {}
      })();
    """.trimIndent()
    webView.evaluateJavascript(js, null)
  }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PortalWebViewApp(activity: FragmentActivity? = null) {
  val context = LocalContext.current
  val coroutineScope = rememberCoroutineScope()
  val isDarkTheme = isSystemInDarkTheme()
  val portalUrl = "https://rossofuoco.eu/personale/"

  var isAuthenticated by remember { mutableStateOf(false) }
  var authErrorMessage by remember { mutableStateOf<String?>(null) }

  // Notification permission requester (Android 13+) using 16-bit safe request code for FragmentActivity
  LaunchedEffect(Unit) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && activity != null) {
      if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
        ActivityCompat.requestPermissions(
          activity,
          arrayOf(Manifest.permission.POST_NOTIFICATIONS),
          1001
        )
      }
    }
  }

  // Check biometric availability
  LaunchedEffect(Unit) {
    if (activity != null) {
      launchBiometricAuth(
        activity = activity,
        onSuccess = {
          isAuthenticated = true
          authErrorMessage = null
        },
        onError = { err ->
          authErrorMessage = err
        }
      )
    } else {
      isAuthenticated = true
    }
  }

  if (!isAuthenticated) {
    Surface(
      modifier = Modifier
        .fillMaxSize()
        .testTag("biometric_lock_screen"),
      color = MaterialTheme.colorScheme.background
    ) {
      Column(
        modifier = Modifier
          .fillMaxSize()
          .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
      ) {
        Surface(
          shape = MaterialTheme.shapes.extraLarge,
          color = MaterialTheme.colorScheme.primaryContainer,
          modifier = Modifier.size(100.dp)
        ) {
          Box(contentAlignment = Alignment.Center) {
            Icon(
              imageVector = Icons.Default.Lock,
              contentDescription = "Blocco di sicurezza",
              modifier = Modifier.size(48.dp),
              tint = MaterialTheme.colorScheme.onPrimaryContainer
            )
          }
        }

        Spacer(modifier = Modifier.height(28.dp))

        Text(
          text = "RossoFuoco Personale",
          style = MaterialTheme.typography.headlineMedium,
          color = MaterialTheme.colorScheme.onBackground
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
          text = "Accesso protetto da autenticazione biometrica",
          style = MaterialTheme.typography.bodyMedium,
          color = MaterialTheme.colorScheme.onSurfaceVariant,
          textAlign = TextAlign.Center
        )

        if (authErrorMessage != null) {
          Spacer(modifier = Modifier.height(16.dp))
          Text(
            text = authErrorMessage ?: "",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
            textAlign = TextAlign.Center
          )
        }

        Spacer(modifier = Modifier.height(36.dp))

        Button(
          onClick = {
            if (activity != null) {
              launchBiometricAuth(
                activity = activity,
                onSuccess = {
                  isAuthenticated = true
                  authErrorMessage = null
                },
                onError = { err ->
                  authErrorMessage = err
                }
              )
            } else {
              isAuthenticated = true
            }
          },
          modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .testTag("unlock_biometric_button")
        ) {
          Icon(
            imageVector = Icons.Default.Fingerprint,
            contentDescription = null,
            modifier = Modifier.size(24.dp)
          )
          Spacer(modifier = Modifier.width(12.dp))
          Text(
            text = "Sblocca con Biometria / PIN",
            style = MaterialTheme.typography.titleMedium
          )
        }
      }
    }
    return
  }

  var webView by remember { mutableStateOf<WebView?>(null) }
  var currentUrl by remember { mutableStateOf(portalUrl) }
  var pageTitle by remember { mutableStateOf("RossoFuoco Personale") }
  var progress by remember { mutableStateOf(0) }
  var isLoading by remember { mutableStateOf(true) }
  var isRefreshing by remember { mutableStateOf(false) }
  var hasError by remember { mutableStateOf(false) }
  var errorMessage by remember { mutableStateOf("") }
  var canGoBack by remember { mutableStateOf(false) }

  val snackbarHostState = remember { SnackbarHostState() }
  val connectivityFlow = remember { observeConnectivity(context) }
  val isConnected by connectivityFlow.collectAsState(initial = true)

  var previousConnectionState by remember { mutableStateOf<Boolean?>(null) }

  val animatedProgress by animateFloatAsState(
    targetValue = if (isLoading && progress < 100) (progress / 100f).coerceIn(0.05f, 1f) else 1f,
    animationSpec = tween(durationMillis = 250),
    label = "webViewProgress"
  )

  LaunchedEffect(isDarkTheme) {
    webView?.let {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        it.settings.isAlgorithmicDarkeningAllowed = isDarkTheme
      }
      injectThemeMode(it, isDarkTheme)
    }
  }

  LaunchedEffect(isConnected) {
    if (previousConnectionState != null) {
      if (!isConnected) {
        snackbarHostState.showSnackbar("Connessione Internet assente")
      } else if (isConnected && previousConnectionState == false) {
        snackbarHostState.showSnackbar("Connessione ripristinata. Aggiornamento in corso...")
        hasError = false
        webView?.reload()
      }
    }
    previousConnectionState = isConnected
  }

  // Handle system back button for WebView navigation
  BackHandler(enabled = canGoBack) {
    webView?.goBack()
  }

  Scaffold(
    contentWindowInsets = WindowInsets.statusBars,
    snackbarHost = { SnackbarHost(snackbarHostState) }
  ) { innerPadding ->
    Box(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
    ) {
      PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = {
          isRefreshing = true
          webView?.reload()
        },
        modifier = Modifier.fillMaxSize()
      ) {
        Box(modifier = Modifier.fillMaxSize()) {
          AndroidView(
            modifier = Modifier
              .fillMaxSize()
              .testTag("webview"),
            factory = { ctx ->
              WebView(ctx).apply {
                layoutParams = ViewGroup.LayoutParams(
                  ViewGroup.LayoutParams.MATCH_PARENT,
                  ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(if (isDarkTheme) AndroidColor.parseColor("#121212") else AndroidColor.WHITE)
                settings.apply {
                  javaScriptEnabled = true
                  domStorageEnabled = true
                  loadWithOverviewMode = true
                  useWideViewPort = true
                  setSupportZoom(true)
                  builtInZoomControls = true
                  displayZoomControls = false
                  setGeolocationEnabled(true)
                  javaScriptCanOpenWindowsAutomatically = true
                  userAgentString = "${userAgentString} RossoFuocoMobileApp/1.0 (Android; MobileClient)"
                  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    isAlgorithmicDarkeningAllowed = isDarkTheme
                  }
                }

                // Attach Native Javascript Interface Bridge
                val bridge = NativeBridge(
                  context = ctx,
                  onSyncReceived = { dataType, _ ->
                    coroutineScope.launch {
                      snackbarHostState.showSnackbar("Dati sincronizzati: $dataType")
                    }
                  },
                  onSnackbarMessage = { msg ->
                    coroutineScope.launch {
                      snackbarHostState.showSnackbar(msg)
                    }
                  }
                )
                addJavascriptInterface(bridge, NativeBridge.JS_INTERFACE_NAME)

                setDownloadListener { url, userAgent, contentDisposition, mimetype, _ ->
                  try {
                    val filename = URLUtil.guessFileName(url, contentDisposition, mimetype)
                    val request = DownloadManager.Request(Uri.parse(url)).apply {
                      setMimeType(mimetype)
                      val cookies = CookieManager.getInstance().getCookie(url)
                      if (cookies != null) {
                        addRequestHeader("cookie", cookies)
                      }
                      addRequestHeader("User-Agent", userAgent)
                      setDescription("Download dal portale RossoFuoco")
                      setTitle(filename)
                      setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                      setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, filename)
                    }
                    val dm = ctx.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                    dm.enqueue(request)
                    coroutineScope.launch {
                      snackbarHostState.showSnackbar("Download avviato: $filename")
                    }
                  } catch (e: Exception) {
                    coroutineScope.launch {
                      snackbarHostState.showSnackbar("Errore durante il download: ${e.localizedMessage ?: "Sconosciuto"}")
                    }
                  }
                }
                webViewClient = object : WebViewClient() {
                  override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    isLoading = true
                    hasError = false
                    url?.let { currentUrl = it }
                    injectThemeMode(view, isDarkTheme)
                    injectHybridBridge(view)
                  }

                  override fun onPageCommitVisible(view: WebView?, url: String?) {
                    super.onPageCommitVisible(view, url)
                    injectThemeMode(view, isDarkTheme)
                    injectHybridBridge(view)
                  }

                  override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    isLoading = false
                    isRefreshing = false
                    url?.let { currentUrl = it }
                    view?.title?.let { if (it.isNotBlank()) pageTitle = it }
                    canGoBack = view?.canGoBack() ?: false
                    injectThemeMode(view, isDarkTheme)
                    injectHybridBridge(view)
                  }

                  override fun onReceivedError(
                    view: WebView?,
                    request: WebResourceRequest?,
                    error: WebResourceError?
                  ) {
                    super.onReceivedError(view, request, error)
                    if (request?.isForMainFrame == true) {
                      hasError = true
                      errorMessage = error?.description?.toString() ?: "Errore di connessione"
                      isLoading = false
                      isRefreshing = false
                    }
                  }
                }
                webChromeClient = object : WebChromeClient() {
                  override fun onProgressChanged(view: WebView?, newProgress: Int) {
                    super.onProgressChanged(view, newProgress)
                    progress = newProgress
                    if (newProgress >= 100) {
                      isLoading = false
                      isRefreshing = false
                    }
                    canGoBack = view?.canGoBack() ?: false
                    if (newProgress > 30) {
                      injectThemeMode(view, isDarkTheme)
                      injectHybridBridge(view)
                    }
                  }

                  override fun onReceivedTitle(view: WebView?, title: String?) {
                    super.onReceivedTitle(view, title)
                    title?.let { if (it.isNotBlank()) pageTitle = it }
                  }
                }
                loadUrl(portalUrl)
                webView = this
              }
            },
            update = { view ->
              webView = view
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                view.settings.isAlgorithmicDarkeningAllowed = isDarkTheme
              }
              view.setBackgroundColor(if (isDarkTheme) AndroidColor.parseColor("#121212") else AndroidColor.WHITE)
              injectThemeMode(view, isDarkTheme)
              injectHybridBridge(view)
            }
          )

          if (hasError) {
            Surface(
              modifier = Modifier.fillMaxSize(),
              color = MaterialTheme.colorScheme.surface
            ) {
              Column(
                modifier = Modifier
                  .fillMaxSize()
                  .padding(24.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
              ) {
                Icon(
                  imageVector = Icons.Default.Refresh,
                  contentDescription = null,
                  modifier = Modifier.size(64.dp),
                  tint = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                  text = "Impossibile caricare la pagina",
                  style = MaterialTheme.typography.titleLarge,
                  color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                  text = errorMessage.ifEmpty { "Controlla la tua connessione a internet e riprova." },
                  style = MaterialTheme.typography.bodyMedium,
                  color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(24.dp))
                Button(
                  onClick = {
                    hasError = false
                    isLoading = true
                    isRefreshing = true
                    webView?.reload()
                  },
                  modifier = Modifier.testTag("retry_button")
                ) {
                  Icon(imageVector = Icons.Default.Refresh, contentDescription = null)
                  Spacer(modifier = Modifier.width(8.dp))
                  Text("Riprova")
                }
              }
            }
          }
        }
      }

      // Linear progress bar overlay at the top of the fullscreen view
      AnimatedVisibility(
        visible = (isLoading || progress < 100) && !isRefreshing,
        enter = fadeIn(),
        exit = fadeOut(),
        modifier = Modifier.align(Alignment.TopCenter)
      ) {
        LinearProgressIndicator(
          progress = { animatedProgress },
          modifier = Modifier
            .fillMaxWidth()
            .height(3.dp)
            .testTag("loading_progress_bar"),
          color = MaterialTheme.colorScheme.primary,
          trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        )
      }
    }
  }
}
