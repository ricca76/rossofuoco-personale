import Foundation
import LocalAuthentication

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var biometricTypeString: String = "Biometria"

    init() {
        checkBiometryType()
    }

    func checkBiometryType() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                biometricTypeString = "Face ID"
            case .touchID:
                biometricTypeString = "Touch ID"
            case .opticID:
                biometricTypeString = "Optic ID"
            default:
                biometricTypeString = "Biometria"
            }
        }
    }

    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Annulla"
        context.localizedFallbackTitle = "Usa Codice"

        var error: NSError?
        let reason = "Accedi al Portale del Personale RossoFuoco"

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isAuthenticated = success
                    completion(success)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isAuthenticated = true
                completion(true)
            }
        }
    }
}
