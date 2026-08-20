import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @State private var isLoading = true
    @State private var hasError = false
    @State private var canGoBack = false
    @State private var webView: WKWebView? = nil
    
    private let targetURL = URL(string: "https://rossofuoco.eu/personale/")!
    private let primaryColor = Color(red: 0.88, green: 0.27, blue: 0.18) // #E0452E
    private let darkBackground = Color(red: 0.08, green: 0.07, blue: 0.06) // #141210

    var body: some View {
        ZStack {
            darkBackground
                .ignoresSafeArea()

            if authManager.isUnlocked {
                // Vista Principale
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                            .scaleEffect(1.2)
                            .frame(height: 36)
                            .padding(.top, 4)
                    }

                    if hasError {
                        // Vista Errore Connessione
                        VStack(spacing: 16) {
                            Spacer()

                            Image(systemName: "wifi.slash")
                                .font(.system(size: 50))
                                .foregroundColor(primaryColor)

                            Text("Impossibile caricare il portale")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Verifica la connessione internet e tocca Ricarica.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Button(action: {
                                hasError = false
                                isLoading = true
                                webView?.reload()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Ricarica Pagina")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(primaryColor)
                                .cornerRadius(10)
                            }
                            .padding(.top, 8)

                            Spacer()
                        }
                    } else {
                        WebViewContainer(
                            url: targetURL,
                            isLoading: $isLoading,
                            canGoBack: $canGoBack,
                            hasError: $hasError,
                            webViewReference: $webView
                        )
                        .ignoresSafeArea(.all, edges: .all)
                    }
                }
            } else {
                // Schermata di blocco biometrico
                VStack(spacing: 24) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color(red: 0.16, green: 0.10, blue: 0.08))
                            .frame(width: 100, height: 100)

                        Image(systemName: "flame.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .foregroundColor(primaryColor)
                    }

                    Text("RossoFuoco Personale")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Accesso protetto. Autenticati con Face ID o codice per accedere al portale.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if let error = authManager.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer()

                    Button(action: {
                        authManager.authenticate()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "faceid")
                                .font(.title3)
                            Text("Sblocca Portale")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(primaryColor)
                        .cornerRadius(14)
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
