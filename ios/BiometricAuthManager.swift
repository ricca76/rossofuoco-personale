import Foundation
import LocalAuthentication

class BiometricAuthManager: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var authError: String? = nil
    @Published var isAuthenticating: Bool = false

    func authenticate(completion: ((Bool) -> Void)? = nil) {
        guard !isAuthenticating else { return }
        
        let context = LAContext()
        context.localizedCancelTitle = "Annulla"
        context.localizedFallbackTitle = "Usa Codice PIN"
        
        var error: NSError?
        let canEvaluateBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluateBiometrics {
            self.isAuthenticating = true
            let reason = "Autenticati con Face ID o Touch ID per accedere a RossoFuoco Personale"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, evalError in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    if success {
                        self?.isUnlocked = true
                        self?.authError = nil
                        completion?(true)
                    } else if let laError = evalError as? LAError, laError.code == .userFallback {
                        self?.fallbackToPasscode(completion: completion)
                    } else {
                        self?.authError = "Autenticazione non riuscita. Tocca per riprovare."
                        completion?(false)
                    }
                }
            }
        } else {
            // Se la biometria non è disponibile o configurata, prova con il passcode del dispositivo
            fallbackToPasscode(completion: completion)
        }
    }

    private func fallbackToPasscode(completion: ((Bool) -> Void)? = nil) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            self.isAuthenticating = true
            let reason = "Inserisci il codice di sblocco per accedere a RossoFuoco Personale"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, evalError in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    if success {
                        self?.isUnlocked = true
                        self?.authError = nil
                        completion?(true)
                    } else {
                        self?.authError = "Autenticazione richiesta per accedere."
                        completion?(false)
                    }
                }
            }
        } else {
            // Nessun meccanismo di sicurezza sul dispositivo: sblocca direttamente
            DispatchQueue.main.async {
                self.isUnlocked = true
                self.authError = nil
                completion?(true)
            }
        }
    }
}
