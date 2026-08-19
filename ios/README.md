# RossoFuoco Personale — App Nativa iOS (Swift & SwiftUI)

Questa cartella contiene il codice sorgente nativo per l'applicazione iOS di **RossoFuoco Personale**.

## Caratteristiche
- **SwiftUI + WKWebView**: Prestazioni native, supporto swipe gestures e pull-to-refresh.
- **Autenticazione Biometrica**: Supporto a **Face ID** e **Touch ID** con fallback automatico su Passcode dispositivo (`LocalAuthentication`).
- **Tema Scuro Nativo**: Look & feel coordinato con i colori del brand RossoFuoco (`#141210` e `#E0442E`).
- **Bridge JavaScript**: Oggetto `window.RossoFuoco` compatibile con le chiamate web per feedback aptico e gestione sessione.

## Come creare il progetto in Xcode:
1. Apri **Xcode** su Mac e seleziona **Create a new Xcode project**.
2. Scegli **iOS -> App**.
3. Inserisci:
   - **Product Name**: `RossoFuoco Personale`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
4. Copia i file presenti in questa cartella nella cartella principale del progetto Xcode:
   - `RossoFuocoApp.swift`
   - `ContentView.swift`
   - `WebViewContainer.swift`
   - `BiometricAuthManager.swift`
   - `Info.plist` (o copia le chiavi `NSFaceIDUsageDescription` nelle proprietà del target).
5. Collega il tuo iPhone o seleziona un simulatore e premi il pulsante **Play (Run)** per installare l'app.
