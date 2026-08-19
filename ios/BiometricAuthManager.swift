import Foundation
import LocalAuthentication

class BiometricAuthManager: ObservableObject {
    @Published var isUnlocked = false
    @Published var authError: String? = nil

    func authenticate(completion: ((Bool) -> Void)? = nil) {
        let context = LAContext()
        context.localizedCancelTitle = "Annulla"
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Autenticati con Face ID o Touch ID per accedere a RossoFuoco Personale"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.isUnlocked = true
                        self?.authError = nil
                        completion?(true)
                    } else {
                        // Fallback con codice di sblocco dispositivo
                        self?.fallbackToDevicePasscode(completion: completion)
                    }
                }
            }
        } else {
            // Se la biometria non è configurata, usa il PIN/passcode del dispositivo
            fallbackToDevicePasscode(completion: completion)
        }
    }

    private func fallbackToDevicePasscode(completion: ((Bool) -> Void)? = nil) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Inserisci il codice di sblocco per accedere a RossoFuoco Personale"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        self?.isUnlocked = true
                        self?.authError = nil
                        completion?(true)
                    } else {
                        self?.authError = "Autenticazione richiesta per accedere"
                        completion?(false)
                    }
                }
            }
        } else {
            // Nessun blocco dispositivo presente: consenti l'accesso diretto
            DispatchQueue.main.async {
                self.isUnlocked = true
                completion?(true)
            }
        }
    }
}
