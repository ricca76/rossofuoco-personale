import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = BiometricAuthManager()
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var reloadTrigger = false

    private let portalURL = URL(string: "https://rossofuoco.eu/personale/")!
    private let rossoColor = Color(red: 211/255, green: 47/255, blue: 47/255)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header Bar
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 34, height: 34)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                            .foregroundColor(rossoColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("RossoFuoco")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Text("Portale del Personale")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Button(action: {
                        reloadTrigger = true
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }

                    Button(action: {
                        authManager.authenticate { _ in }
                    }) {
                        Image(systemName: authManager.biometricTypeString.contains("Face") ? "faceid" : "touchid")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(rossoColor)

                // Loading Indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle(tint: rossoColor))
                        .frame(height: 2)
                }

                // Web Content
                WebViewContainer(
                    url: portalURL,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    reloadTrigger: $reloadTrigger,
                    onBiometricRequested: {
                        authManager.authenticate { _ in }
                    }
                )

                // Bottom Navigation
                HStack {
                    Button(action: {
                        // Back action
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(canGoBack ? rossoColor : Color.gray.opacity(0.4))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!canGoBack)

                    Button(action: {
                        // Forward action
                    }) {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(canGoForward ? rossoColor : Color.gray.opacity(0.4))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!canGoForward)

                    Spacer()

                    Button(action: {
                        reloadTrigger = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 14))
                            Text("Home")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(rossoColor.opacity(0.12))
                        .foregroundColor(rossoColor)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: -2)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
