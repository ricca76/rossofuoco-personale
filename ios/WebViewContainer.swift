import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var hasError: Bool
    @Binding var reloadTrigger: Bool
    var onBiometricRequested: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // Inietta bridge nativo, viewport meta responsivo e blocco dell'auto-scaling sfasato
        let setupScript = WKUserScript(
            source: """
            window.RossoFuocoNative = {
                triggerBiometricAuth: function() {
                    window.webkit.messageHandlers.biometricHandler.postMessage('auth');
                }
            };

            (function() {
                function applyMobileViewport() {
                    var meta = document.querySelector('meta[name="viewport"]');
                    if (!meta) {
                        meta = document.createElement('meta');
                        meta.name = 'viewport';
                        document.head.appendChild(meta);
                    }
                    meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover');
                    
                    var style = document.getElementById('native-screen-fix');
                    if (!style) {
                        style = document.createElement('style');
                        style.id = 'native-screen-fix';
                        style.innerHTML = `
                            html, body {
                                -webkit-text-size-adjust: 100% !important;
                                text-size-adjust: 100% !important;
                                max-width: 100vw !important;
                                box-sizing: border-box !important;
                            }
                        `;
                        if (document.head) {
                            document.head.appendChild(style);
                        }
                    }
                }
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', applyMobileViewport);
                } else {
                    applyMobileViewport();
                }
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(setupScript)
        userContentController.add(context.coordinator, name: "biometricHandler")
        configuration.userContentController = userContentController
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.customUserAgent = (webView.customUserAgent ?? "") + " RossoFuocoApp/1.0 Mobile"

        // Native Pull-to-refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl(sender:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 211/255, green: 47/255, blue: 47/255, alpha: 1.0)
        webView.scrollView.refreshControl = refreshControl

        context.coordinator.webView = webView
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if reloadTrigger {
            uiView.reload()
            DispatchQueue.main.async {
                self.reloadTrigger = false
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        weak var webView: WKWebView?

        init(_ parent: WebViewContainer) {
            self.parent = parent
        }

        @objc func handleRefreshControl(sender: UIRefreshControl) {
            webView?.reload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                sender.endRefreshing()
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "biometricHandler" {
                parent.onBiometricRequested?()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.hasError = false
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.hasError = false
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.hasError = true
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.hasError = true
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }
    }
}
