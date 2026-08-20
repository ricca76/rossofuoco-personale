import React, { useState, useEffect, useRef } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  ActivityIndicator,
  BackHandler,
  Platform,
  SafeAreaView,
  RefreshControl,
  ScrollView,
  useColorScheme,
  StatusBar as RNStatusBar
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { WebView } from 'react-native-webview';
import * as LocalAuthentication from 'expo-local-authentication';
import * as Network from 'expo-network';
import * as Haptics from 'expo-haptics';

const TARGET_URL = 'https://rossofuoco.eu/personale/';
const PRIMARY_COLOR = '#E0452E';
const DARK_BG = '#141210';
const CARD_DARK = '#1F1B18';

export default function App() {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';
  
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authError, setAuthError] = useState(null);
  const [hasBiometricHardware, setHasBiometricHardware] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [hasNetworkError, setHasNetworkError] = useState(false);
  const [isConnected, setIsConnected] = useState(true);
  const [canGoBack, setCanGoBack] = useState(false);
  const [progress, setProgress] = useState(0);

  const webViewRef = useRef(null);

  // Check biometric support & authenticate on app launch
  useEffect(() => {
    checkAndAuthenticate();
  }, []);

  // Monitor network connectivity
  useEffect(() => {
    const checkNetwork = async () => {
      try {
        const netInfo = await Network.getNetworkStateAsync();
        setIsConnected(netInfo.isConnected && netInfo.isInternetReachable !== false);
      } catch (e) {
        setIsConnected(true);
      }
    };
    checkNetwork();
    const interval = setInterval(checkNetwork, 5000);
    return () => clearInterval(interval);
  }, []);

  // Android hardware back button handler
  useEffect(() => {
    if (Platform.OS === 'android') {
      const onBackPress = () => {
        if (canGoBack && webViewRef.current) {
          webViewRef.current.goBack();
          return true;
        }
        return false;
      };
      const subscription = BackHandler.addEventListener('hardwareBackPress', onBackPress);
      return () => subscription.remove();
    }
  }, [canGoBack]);

  const checkAndAuthenticate = async () => {
    try {
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = await LocalAuthentication.isEnrolledAsync();
      setHasBiometricHardware(hasHardware && isEnrolled);

      if (!hasHardware || !isEnrolled) {
        // Se non supportato o non configurato sul dispositivo, sblocca direttamente
        setIsAuthenticated(true);
        return;
      }

      const result = await LocalAuthentication.authenticateAsync({
        promptMessage: 'Accedi a RossoFuoco Personale',
        cancelLabel: 'Annulla',
        fallbackLabel: 'Usa Codice PIN',
        disableDeviceFallback: false,
      });

      if (result.success) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        setIsAuthenticated(true);
        setAuthError(null);
      } else {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        setAuthError('Autenticazione non riuscita. Riprova per accedere.');
      }
    } catch (error) {
      // In caso di errore insolito, consenti l'accesso di fallback
      setIsAuthenticated(true);
    }
  };

  const handleRefresh = () => {
    setIsRefreshing(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (webViewRef.current) {
      webViewRef.current.reload();
    } else {
      setIsRefreshing(false);
    }
  };

  const handleRetry = () => {
    setHasNetworkError(false);
    setIsLoading(true);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    if (webViewRef.current) {
      webViewRef.current.reload();
    }
  };

  // Injected JavaScript for Native Bridge and Auto Dark Theme
  const injectedJavaScript = `
    (function() {
      try {
        if (!window.RossoFuoco) {
          window.RossoFuoco = {
            notify: function(title, message) {
              window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'notify', title: title, message: message }));
            },
            toast: function(message) {
              window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'toast', message: message }));
            },
            sync: function(dataType, data) {
              window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'sync', dataType: dataType, data: data }));
            },
            getInfo: function() {
              return { platform: '${Platform.OS}', app: 'RossoFuoco', version: '1.0.0' };
            }
          };

          var readyEvent = new CustomEvent('RossoFuocoNativeReady', { detail: window.RossoFuoco.getInfo() });
          window.dispatchEvent(readyEvent);
          document.dispatchEvent(readyEvent);
        }

        // Dark Theme Injection
        ${isDark ? `
          document.documentElement.setAttribute('data-theme', 'dark');
          document.documentElement.setAttribute('data-bs-theme', 'dark');
          document.documentElement.classList.add('dark');
          if (document.body) document.body.classList.add('dark');
        ` : `
          document.documentElement.removeAttribute('data-theme');
          document.documentElement.removeAttribute('data-bs-theme');
          document.documentElement.classList.remove('dark');
          if (document.body) document.body.classList.remove('dark');
        `}
      } catch(e) {}
    })();
    true;
  `;

  // Schermata di blocco biometrico
  if (!isAuthenticated) {
    return (
      <SafeAreaView style={[styles.container, { backgroundColor: DARK_BG }]}>
        <StatusBar style="light" />
        <View style={styles.authContainer}>
          <View style={styles.authIconContainer}>
            <Text style={styles.flameEmoji}>🔥</Text>
          </View>

          <Text style={styles.authTitle}>RossoFuoco Personale</Text>
          <Text style={styles.authSubtitle}>
            Accesso protetto da autenticazione biometrica (Face ID / Touch ID / PIN)
          </Text>

          {authError && (
            <View style={styles.errorBox}>
              <Text style={styles.errorText}>{authError}</Text>
            </View>
          )}

          <TouchableOpacity
            style={styles.unlockButton}
            onPress={checkAndAuthenticate}
            activeOpacity={0.8}
          >
            <Text style={styles.unlockButtonText}>Sblocca Portale</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={[styles.container, { backgroundColor: isDark ? DARK_BG : '#FFFFFF' }]}>
      <StatusBar style={isDark ? 'light' : 'dark'} />

      {/* Connection warning bar */}
      {!isConnected && (
        <View style={styles.offlineBanner}>
          <Text style={styles.offlineBannerText}>⚠️ Connessione Internet assente</Text>
        </View>
      )}

      {/* Linear progress bar */}
      {isLoading && progress < 1 && (
        <View style={styles.progressBarBackground}>
          <View style={[styles.progressBarFill, { width: `${Math.max(progress * 100, 10)}%` }]} />
        </View>
      )}

      {/* Main WebView or Error View */}
      {hasNetworkError ? (
        <ScrollView
          contentContainerStyle={styles.errorContainer}
          refreshControl={<RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} tintColor={PRIMARY_COLOR} />}
        >
          <Text style={styles.errorEmoji}>📡</Text>
          <Text style={[styles.errorHeading, { color: isDark ? '#FFFFFF' : '#1F1B18' }]}>
            Impossibile caricare il portale
          </Text>
          <Text style={styles.errorDescription}>
            Verifica la tua connessione a internet e tocca Riprova per accedere a RossoFuoco.
          </Text>
          <TouchableOpacity style={styles.retryButton} onPress={handleRetry} activeOpacity={0.8}>
            <Text style={styles.retryButtonText}>Ricarica Pagina</Text>
          </TouchableOpacity>
        </ScrollView>
      ) : (
        <View style={styles.webViewWrapper}>
          <WebView
            ref={webViewRef}
            source={{ uri: TARGET_URL }}
            style={[styles.webView, { backgroundColor: isDark ? DARK_BG : '#FFFFFF' }]}
            injectedJavaScript={injectedJavaScript}
            javaScriptEnabled={true}
            domStorageEnabled={true}
            allowsBackForwardNavigationGestures={true}
            pullToRefreshEnabled={true}
            userAgent="RossoFuocoMobileApp/1.0 (iOS/Android; Expo)"
            onLoadProgress={({ nativeEvent }) => setProgress(nativeEvent.progress)}
            onLoadStart={() => {
              setIsLoading(true);
              setHasNetworkError(false);
            }}
            onLoadEnd={() => {
              setIsLoading(false);
              setIsRefreshing(false);
            }}
            onError={() => {
              setHasNetworkError(true);
              setIsLoading(false);
              setIsRefreshing(false);
            }}
            onNavigationStateChange={(navState) => {
              setCanGoBack(navState.canGoBack);
            }}
            onMessage={(event) => {
              try {
                const data = JSON.parse(event.nativeEvent.data);
                if (data.type === 'toast' || data.type === 'notify') {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                }
              } catch (e) {}
            }}
          />
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: Platform.OS === 'android' ? RNStatusBar.currentHeight : 0,
  },
  authContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 28,
  },
  authIconContainer: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: '#2A1815',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 24,
    borderWidth: 2,
    borderColor: PRIMARY_COLOR,
  },
  flameEmoji: {
    fontSize: 44,
  },
  authTitle: {
    fontSize: 26,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 10,
    textAlign: 'center',
  },
  authSubtitle: {
    fontSize: 15,
    color: '#A09890',
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 32,
    paddingHorizontal: 12,
  },
  errorBox: {
    backgroundColor: '#3A1412',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 10,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#7F1D1D',
  },
  errorText: {
    color: '#FCA5A5',
    fontSize: 14,
    textAlign: 'center',
  },
  unlockButton: {
    backgroundColor: PRIMARY_COLOR,
    width: '100%',
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: 'center',
    shadowColor: PRIMARY_COLOR,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 4,
  },
  unlockButtonText: {
    color: '#FFFFFF',
    fontSize: 17,
    fontWeight: '600',
    letterSpacing: 0.3,
  },
  offlineBanner: {
    backgroundColor: '#D97706',
    paddingVertical: 8,
    paddingHorizontal: 16,
    alignItems: 'center',
  },
  offlineBannerText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '600',
  },
  progressBarBackground: {
    height: 3,
    backgroundColor: 'rgba(224, 69, 46, 0.2)',
    width: '100%',
  },
  progressBarFill: {
    height: 3,
    backgroundColor: PRIMARY_COLOR,
  },
  webViewWrapper: {
    flex: 1,
  },
  webView: {
    flex: 1,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  errorEmoji: {
    fontSize: 56,
    marginBottom: 16,
  },
  errorHeading: {
    fontSize: 22,
    fontWeight: '700',
    marginBottom: 10,
    textAlign: 'center',
  },
  errorDescription: {
    fontSize: 15,
    color: '#8A8580',
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: 28,
  },
  retryButton: {
    backgroundColor: PRIMARY_COLOR,
    paddingVertical: 14,
    paddingHorizontal: 28,
    borderRadius: 12,
  },
  retryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
});
