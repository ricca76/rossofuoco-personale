import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @State private var isLoading = true
    @State private var hasError = false
    @State private var reloadTrigger = false

    private let portalURL = URL(string: "https://rossofuoco.eu/personale/")!
    private let rossoColor = Color(red: 211/255, green: 47/255, blue: 47/255)

    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea(.all)

            // Full Screen Edge-to-Edge WebView
            WebViewContainer(
                url: portalURL,
                isLoading: $isLoading,
                hasError: $hasError,
                reloadTrigger: $reloadTrigger,
                onBiometricRequested: {
                    authManager.authenticate { _ in }
                }
            )
            .opacity(hasError ? 0 : 1)
            .ignoresSafeArea(.all)

            // Subtle loading indicator at top edge
            if isLoading && !hasError {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: rossoColor))
                    .frame(height: 3)
                    .ignoresSafeArea(edges: .horizontal)
            }

            // Offline / Error screen if network fails
            if hasError {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 56))
                        .foregroundColor(rossoColor)

                    Text("Nessuna Connessione")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Impossibile caricare il portale RossoFuoco.\nVerifica la connessione internet e riprova.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button(action: {
                        hasError = false
                        reloadTrigger = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Riprova")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(rossoColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: rossoColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 10)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
                .ignoresSafeArea(.all)
            }
        }
    }
}
