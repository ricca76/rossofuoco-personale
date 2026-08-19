import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var webView: WKWebView? = nil
    
    private let targetURL = URL(string: "https://rossofuoco.eu/personale/")!

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.07, blue: 0.06) // #141210 Dark background
                .ignoresSafeArea()

            if authManager.isUnlocked {
                // Schermata principale con la WebView Fullscreen
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.88, green: 0.27, blue: 0.18)))
                            .padding(.top, 8)
                    }

                    WebViewContainer(
                        url: targetURL,
                        isLoading: $isLoading,
                        canGoBack: $canGoBack,
                        webViewReference: $webView
                    )
                    .ignoresSafeArea(.all, edges: .all)
                }
            } else {
                // Schermata di blocco biometrico
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "flame.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(Color(red: 0.88, green: 0.27, blue: 0.18))

                    Text("RossoFuoco Personale")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Autenticati con Face ID / Touch ID per accedere al portale.")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if let error = authManager.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    Spacer()

                    Button(action: {
                        authManager.authenticate()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                                .font(.title3)
                            Text("Sblocca con Biometria")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.88, green: 0.27, blue: 0.18))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            authManager.authenticate()
        }
    }
}

#Preview {
    ContentView()
}
