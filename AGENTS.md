# Regole di Automazione e Istruzioni Agente

## Massima Automazione ed Esecuzione Autonoma
1. **Esecuzione Diretta End-to-End**: Automatizzare al massimo ogni richiesta dell'utente. Gestire ed eseguire direttamente e in totale autonomia tutte le azioni necessarie per completare il task (scrittura del codice, correzione errori, sincronizzazione repository GitHub, pipeline CI/CD, build, packaging e deploy su TestFlight / store).
2. **Proattività e Risoluzione Problemi**: Se si verificano errori o blocchi tecnici (es. compilazione, lint, certificati Apple, validazioni SDK, API GitHub), risolverli immediatamente ed iterativamente in background senza richiedere conferme all'utente per passaggi intermedi ordinari.
3. **Flusso di Lavoro Continuo**: Non fermarsi a chiedere conferme per i sub-task sequenziali; completare l'intero flusso richiesto prima di restituire il controllo all'utente con un resoconto chiaro e puntuale.
4. **Interazione Minima per Blocchi Critici**: Coinvolgere l'utente esclusivamente in caso di informazioni esterne mancanti e non recuperabili (es. nuove credenziali o token non presenti nel repository/ambiente) o scelte di business irreversibili.
