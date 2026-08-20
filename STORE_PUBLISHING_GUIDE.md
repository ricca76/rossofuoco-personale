# 🚀 Guida Completa alla Pubblicazione – RossoFuoco Personale

Tutti gli asset grafici (icone, banner 1024x500, screenshot HD per iPhone e Android), i metadati, le descrizioni e le policy sono **pronti e organizzati nelle rispettive cartelle**.

---

## 📁 Riepilogo Risorse nel Progetto

| Tipo Risorsa | Posizione nel Repository | Uso |
| :--- | :--- | :--- |
| **Icona 1024x1024 (iOS)** | `store_assets/icons/app_icon_1024x1024.png` | App Store Connect (1024x1024, no alfa) |
| **Icona 512x512 (Android)** | `store_assets/icons/google_play_icon_512x512.png` | Google Play Console (512x512, 32-bit PNG) |
| **Feature Graphic 1024x500** | `store_assets/android/google_play_feature_graphic_1024x500.png` | Banner obbligatorio Play Store |
| **Screenshot Android (1080x2400)** | `store_assets/android/android_screenshot_*.png` | Scheda principale Play Store |
| **Screenshot iPhone (1290x2796)** | `store_assets/ios/ios_screenshot_*.png` | App Store 6.7" / 6.9" Super Retina |
| **Metadati iOS Fastlane** | `ios/fastlane/metadata/it-IT/` | Titolo, sottotitolo, descrizioni, keyword |
| **Metadati Google Play** | `store_assets/play_store_metadata/it-IT/` | Titolo, breve descrizione, descrizione completa |
| **Informativa Privacy** | `PRIVACY_POLICY.md` | URL Privacy Policy per entrambi gli store |

---

## 🤖 1. Pubblicazione su Google Play Console (Android)

### Passaggi da eseguire sulla [Google Play Console](https://play.google.com/console):
1. **Crea nuova App**:
   - Nome dell'app: `RossoFuoco Personale`
   - Lingua predefinita: `Italiano (it-IT)`
   - Tipo: `App` / `Gratis`
2. **Configurazione Scheda Principale dello Store**:
   - **Breve descrizione** (max 80 caratteri):
     > `Portale dipendenti RossoFuoco: turni di lavoro, bacheca, ferie e richieste.`
   - **Descrizione completa**:
     (Copia il testo da `store_assets/play_store_metadata/it-IT/full_description.txt`)
   - **Icona dell'app**: Carica `store_assets/icons/google_play_icon_512x512.png`
   - **Grafica delle funzioni**: Carica `store_assets/android/google_play_feature_graphic_1024x500.png`
   - **Screenshot per smartphone**: Carica i 3 screenshot da `store_assets/android/`
3. **Questionario Sicurezza dei Dati (Data Safety)**:
   - Dati raccolti: Credenziali utente (ID dipendente) per autenticazione app.
   - Nessun dato condiviso con terze parti.
   - Trasmissione dati crittografata (HTTPS/TLS).
   - Biometria: Nessun dato biometrico raccolto o salvato dall'app (gestito a livello hardware di sistema).
4. **Target di Pubblicazione**:
   - Categoria: `Produttività` / `Aziendale`
   - Target di età: `18 anni e oltre`
   - URL Privacy Policy: link alla privacy policy del tuo sito o al file su GitHub.
5. **Rilascio Build (AAB / APK)**:
   - Carica l'Android App Bundle (`.aab`) o APK generato automaticamente dal workflow GitHub Actions.

---

## 🍎 2. Pubblicazione su Apple App Store Connect (iOS)

### Passaggi da eseguire su [App Store Connect](https://appstoreconnect.apple.com):
1. **Scheda App**:
   - Nome: `RossoFuoco Personale`
   - Sottotitolo: `Portale Ufficiale Dipendenti`
   - Bundle ID: `com.rossofuoco.personale`
   - SKU: `rossofuoco-personale`
2. **Screenshot e Risorse Grafiche**:
   - Schermo iPhone 6.7" / 6.5": Carica i 3 file da `store_assets/ios/`
   - Icona dell'app: `store_assets/icons/app_icon_1024x1024.png`
3. **Descrizione & Parole Chiave**:
   - Testo promozionale: `Gestisci i tuoi turni, le richieste e le comunicazioni aziendali RossoFuoco direttamente dal tuo smartphone.`
   - Parole chiave: `rossofuoco, turni, dipendenti, lavoro, ristorante, personale, ferie, bacheca, orari`
   - Descrizione completa: (Copia da `ios/fastlane/metadata/it-IT/description.txt`)
4. **Privacy dell'App**:
   - Dati utilizzati per monitorare l'utente: **Nessuno**.
   - Dati collegati all'utente: Informazioni di contatto / ID Utente (solo per funzionalità dell'account).
5. **TestFlight / Distribuzione**:
   - Il build viene compilato e caricato automaticamente su TestFlight ad ogni commit grazie a Fastlane e GitHub Actions!
   - Dalla sezione TestFlight puoi promuovere qualsiasi build direttamente alla revisione per App Store.
