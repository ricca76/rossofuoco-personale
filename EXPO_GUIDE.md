# Guida Avvio con Expo Go (iOS & Android)

Il progetto è ora configurato con **Expo (React Native)** per supportare sia lo sviluppo immediato con **Expo Go** su iPhone/Android, sia il deployment con **EAS Build**.

---

## 📲 Come testare l'app su iPhone con Expo Go

1. **Installa Expo Go**:
   - Scarica l'app **Expo Go** gratuitamente da [App Store (iOS)](https://apps.apple.com/app/expo-go/id982107779).

2. **Avvia il server di sviluppo**:
   ```bash
   npx expo start
   ```

3. **Apri l'app su iPhone**:
   - Apri l'app **Fotocamera** su iPhone e inquadra il QR Code mostrato nel terminale, oppure tocca la notifica per aprire l'app in **Expo Go**.
   - Se utilizzi lo stesso account Expo, l'app comparirà automaticamente nell'elenco progetti di Expo Go.

---

## 🚀 Funzionalità Incluse nel Progetto Expo:
- **Autenticazione Biometrica Nativa (`expo-local-authentication`)**:
  - Supporto completo per Face ID (iPhone), Touch ID e codice PIN con fallback.
- **WebView Ottimizzata (`react-native-webview`)**:
  - Caricamento diretto di `https://rossofuoco.eu/personale/`.
  - Iniezione automatica della modalità scura / tema del sistema.
  - Bridge JavaScript nativo (`window.RossoFuoco.notify`, `window.RossoFuoco.toast`, `window.RossoFuoco.sync`).
- **Feedback Aptico (`expo-haptics`)**:
  - Vibrazioni di sistema sulle azioni e sblocco Face ID.
- **Gestione Offline & Riconnessione (`expo-network`)**:
  - Riconoscimento automatico della perdita di connessione e pulsante di ricarica con pull-to-refresh.
- **Compatibilità EAS Build**:
  - Configurazione `eas.json` e `app.json` pronta per generare e inviare i binari nativi ad Apple TestFlight e Google Play.
