# Blue Max - versione digitale

Conversione in Godot 4.7 di **Blue Max** (GDW 1983, edizione italiana Stratelibri 1993): duelli aerei della
Prima Guerra Mondiale sul Fronte Occidentale, 1917-1918. Per uso personale, dal gioco originale.

Si gioca nel browser: https://tannoiser2.github.io/Blue-Max/

## Che cosa c'è

- **Regole complete** del regolamento italiano: le 10 fasi del turno, manovre segrete e simultanee, accelerazione,
  manovre acrobatiche e non ripetibili, quota (picchiata, cabrata, quota massima, atterraggio), tallonamento con
  rivelazione della direzione, combattimento con tutti i modificatori e la Tabella dei Risultati, 72 pedine-danno
  trascritte dalle pedine originali (colpi frontali e posteriori), avvitamento, stallo, inceppamenti, Lewis e caricatori,
  osservatori con il punto cieco, fumo e fuoco, planata, fuga dal proprio bordo, segretezza dei danni.
- **18 aerei** con le loro Tabelle-Movimento (scansioni delle schede originali) e le caratteristiche della tabella.
  Il Sopwith Triplane e l'S.E.5a non hanno la scheda fra le scansioni: usano per ora le manovre del Fokker Dr.I
  e dello Spad VII (`tools/genera_dati.py`, voce `PROVVISORI`).
- **Mappa**: la foto della mappa originale raddrizzata con la griglia esagonale ricalcolata (`tools/griglia*.py`).
- **3D**: aerei da Sketchfab (crediti nel gioco), effetti particellari di mitragliatrici, colpi, fumo, fiamme,
  esplosioni e roghi, aerei che virano, cabrano, fanno l'Immelmann e il tonneau; replay finale del combattimento.
  Mappa: un dito sposta, due dita pizzicano e ruotano (anche iPad); mouse: sinistro sposta, destro ruota, rotella zoom.
- **Tutorial** a turni guidati con l'istruttore, **5 scenari storici**, **schermaglia libera** (fino a 6 aerei per parte,
  ognuno pilotato da te, dal computer o da un telefono), **campagna** gennaio 1917 - novembre 1918 con esperienza,
  abilità speciali, cambio d'aereo e salvataggio su Firebase (`bluemax/campagne/<codice>`).
- **Telefoni**: lo schermo grande apre una stanza (`bluemax/rooms`), i piloti inquadrano il QR code e scelgono
  manovre e raffiche in segreto da `telefono.html`.
- **Computer**: tre livelli (Recluta, Veterano, Asso). Prova le proprie manovre contro un campione di manovre nemiche
  (l'Asso immagina le risposte migliori del nemico) e valuta coda, muso, distanza, quota, bordi e carburante.

## Sviluppo

- `scripts/regole.gd` motore delle regole (senza grafica), `scripts/ia.gd` computer, `scripts/gioco.gd` partita e
  interfaccia, `scripts/mondo.gd` 3D, `scripts/tutorial.gd`, `scripts/campagna.gd`, `scripts/menu.gd`.
- `data/*.json` generati da `tools/genera_dati.py`.
- Prove: `godot --headless --path . tests/sim.tscn` (partite computer contro computer),
  `COSA=campagna godot --headless --path . tests/flusso.tscn`, `tests/foto.tscn` (schermate),
  `node tests/browser.mjs` (versione web con un telefono), `python3 tools/controlla_glifi.py` (niente quadratini).
- Pubblicazione: solo a mano (Actions, *Pubblica*, *Run workflow*) o con un commit che contiene `[pubblica]`.
