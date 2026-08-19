import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var webViewReference: WKWebView?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // Iniezione Script Bridge per compatibilità con l'app Android e web app
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "rossoFuocoBridge")

        let bridgeScriptSource = """
        (function() {
            window.RossoFuoco = {
                platform: 'iOS',
                isApp: true,
                sendToken: function(token) {
                    window.webkit.messageHandlers.rossoFuocoBridge.postMessage({ action: 'sendToken', token: token });
                },
                triggerHaptic: function(style) {
                    window.webkit.messageHandlers.rossoFuocoBridge.postMessage({ action: 'triggerHaptic', style: style || 'medium' });
                },
                requestBiometricAuth: function() {
                    window.webkit.messageHandlers.rossoFuocoBridge.postMessage({ action: 'requestBiometrics' });
                }
            };
        })();
        """
        let userScript = WKUserScript(source: bridgeScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(userScript)
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0)
        webView.scrollView.backgroundColor = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0)
        webView.allowsBackForwardNavigationGestures = true

        // Pull to refresh nativo
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(red: 0.88, green: 0.27, blue: 0.18, alpha: 1.0) // Accent Rosso Fuoco
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        DispatchQueue.main.async {
            self.webViewReference = webView
        }

        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Nessun aggiornamento forzato
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        @objc func handleRefreshControl(_ sender: UIRefreshControl) {
            parent.webViewReference?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sender.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.canGoBack = webView.canGoBack
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
            }
        }

        // Gestione messaggi inviati da JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "rossoFuocoBridge",
                  let body = message.body as? [String: Any],
                  let action = body["action"] as? String else { return }

            switch action {
            case "triggerHaptic":
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            case "sendToken":
                if let token = body["token"] as? String {
                    UserDefaults.standard.set(token, forKey: "rf_session_token")
                }
            default:
                break
            }
        }
    }
}
