# 🛠️ RossoFuoco Mobile - Guida allo Sviluppo & Automazione (Android & iOS)

Benvenuto nella guida ufficiale per lo sviluppo e l'automazione dell'applicazione **RossoFuoco Personale** per **Android** (Kotlin, Jetpack Compose, BiometricPrompt) e **iOS** (Swift, SwiftUI, WebKit, LocalAuthentication, XcodeGen, Fastlane).

---

## 🏗️ Architettura del Progetto

```
rossofuoco-personale/
├── app/                              # Progetto Nativo Android (Jetpack Compose)
│   ├── src/main/java/                # Sorgenti Kotlin (MainActivity, NativeBridge, Theme)
│   ├── src/main/res/                 # Risorse XML, icone adaptive, stringhe, colori
│   └── build.gradle.kts              # Configurazione build Gradle & dipendenze
├── ios/                              # Progetto Nativo iOS (SwiftUI)
│   ├── ContentView.swift             # Vista principale SwiftUI con Edge-to-Edge WebView
│   ├── WebViewContainer.swift        # WKWebView Representable con Bridge JS e Pull-to-refresh
│   ├── BiometricAuthManager.swift    # Gestore Face ID / Touch ID con LocalAuthentication
│   ├── Assets.xcassets/              # Icone native iOS e cataloghi asset
│   └── fastlane/                     # Automazione TestFlight & App Store (Fastfile, Appfile)
├── project.yml                       # Specifica dichiarativa XcodeGen per generare RossoFuoco.xcodeproj
├── scripts/                          # Tooling di automazione per sviluppatori
│   ├── dev.sh                        # CLI di sviluppo per Linux/macOS
│   ├── dev.py                        # CLI cross-platform in Python (Windows/macOS/Linux)
│   └── setup_store_metadata.py       # Validazione e sincronizzazione asset grafici
├── .github/workflows/                # Pipeline CI/CD GitHub Actions
│   ├── ci.yml                        # Validazione automatica test & build su ogni PR
│   ├── deploy-playstore.yml          # Build & Rilascio automatico Android su Google Play
│   ├── deploy-testflight.yml         # Build & Rilascio automatico iOS su TestFlight
│   └── release.yml                   # Creazione automatica Release GitHub con APK e AAB
├── store_assets/                     # Icone HD, screenshot 1290x2796 / 1080x2400 e grafiche
├── PRIVACY_POLICY.md                 # Informativa Privacy conforme agli standard Store
└── STORE_PUBLISHING_GUIDE.md         # Guida passo-passo per Play Store e App Store Connect
```

---

## ⚡ Comandi Rapidi di Sviluppo (CLI Automata)

Abbiamo configurato una CLI unificata per eseguire tutti i comandi con una sola riga:

### Con script Bash (`scripts/dev.sh`):
```bash
# 1. Verifica la presenza di tutti i tool e requisiti di sistema
./scripts/dev.sh check

# 2. Compila APK Debug, APK Release e Bundle AAB per Android
./scripts/dev.sh build-android

# 3. Esegui i test unitari Android
./scripts/dev.sh test-android

# 4. Rigenera il progetto Xcode (RossoFuoco.xcodeproj) su macOS
./scripts/dev.sh generate-ios

# 5. Sincronizza e convalida tutti gli asset e metadati degli store
./scripts/dev.sh validate-assets
```

### Con script Python (`scripts/dev.py` - Cross-platform):
```bash
python3 scripts/dev.py check
python3 scripts/dev.py build-android
python3 scripts/dev.py test-android
python3 scripts/dev.py generate-ios
python3 scripts/dev.py validate-assets
```

---

## 🤖 1. Sviluppo Android (Android Studio / VS Code)

### Requisiti:
- **JDK 17** o superiore.
- **Android Studio Ladybug (2024.2+)** o VS Code con estensioni Android/Kotlin.
- **Gradle 8.11+** (già configurato nel repository).

### Funzionalità Implementate:
- **UI Edge-to-Edge** con Material 3 e tema RossoFuoco custom.
- **WebView Avanzata** con gestione cache, barra di caricamento, gestione errori offline con pulsante "Riprova" e navigazione Back/Forward.
- **Bridge JavaScript (`RossoFuocoNative`)**: per invocare autenticazione biometrica, vibrazioni aptiche e gestione sessione direttamente dalla pagina web.
- **Biometria Hardware**: integrazione `androidx.biometric.BiometricPrompt` per impronta digitale e sblocco sicuro.

---

## 🍎 2. Sviluppo iOS (Xcode / macOS)

### Requisiti:
- **macOS** con **Xcode 16+**.
- **XcodeGen** (`brew install xcodegen`).
- **Fastlane** (`gem install fastlane`).

### Come aprire e modificare il progetto iOS:
1. Esegui `./scripts/dev.sh generate-ios` (o `xcodegen generate`).
2. Verrà generato istantaneamente `RossoFuoco.xcodeproj`.
3. Fai doppio clic su `RossoFuoco.xcodeproj` per aprirlo in Xcode ed eseguire l'app su Simulatore o dispositivo fisico iPhone/iPad!

### Note su XcodeGen:
Non è necessario tracciare file XML `.pbxproj` ingombranti in Git: il file `project.yml` definisce in modo pulito tutti i target, le configurazioni di firma, le versioni di deployment e gli asset.

---

## 🚀 3. Pipeline CI/CD Automatizzate (GitHub Actions)

Ad ogni commit o pull request sul branch `main`, GitHub Actions gestisce automaticamente:

1. **`ci.yml`**:
   - Compila ed esegue i test unitari Android.
   - Compila l'app iOS su runner `macos-15` con Xcode 16 per verificare che non ci siano errori di sintassi Swift o linking.
2. **`deploy-playstore.yml`**:
   - Genera i file `app-release.aab` e `app-release.apk` e li salva negli Artifacts di GitHub Actions.
   - Se è presente il secret `PLAY_STORE_JSON_KEY`, effettua il caricamento automatico nella traccia **Test interni** di Google Play.
3. **`deploy-testflight.yml`**:
   - Incrementa automaticamente il build number.
   - Scarica/aggiorna i certificati e provisioning profile Apple.
   - Compila l'IPA nativo e lo carica direttamente su **TestFlight**.
4. **`release.yml`**:
   - Quando crei un tag (es. `v1.0.0`) o esegui il workflow manualmente, crea una **GitHub Release** allegando direttamente l'APK e l'AAB per il download immediato.

---

## 🔐 Configurazione Segreti GitHub (Opzionale per Auto-Deploy)

Per abilitare il rilascio 100% automatico senza toccare le console web:

| Nome Segreto | Piattaforma | Descrizione |
| :--- | :--- | :--- |
| `PLAY_STORE_JSON_KEY` | Android | Contenuto del file JSON della chiave di servizio Google Play |
| `APP_STORE_CONNECT_KEY_ID` | iOS | Key ID della chiave API creata su App Store Connect |
| `APP_STORE_CONNECT_ISSUER_ID` | iOS | Issuer ID (UUID) da App Store Connect |
| `APP_STORE_CONNECT_API_KEY_BASE64` | iOS | Contenuto in Base64 (o testo p8) della chiave privata App Store Connect |
