class_name Scenari
extends RefCounted
## Scenari del regolamento, assi storici e schermaglia libera.

const ASSI := {
	"richthofen": {"nome": "Manfred von Richthofen", "titolo": "Il Barone Rosso", "nazione": "germania", "esperienza": 760, "abbattimenti": 16,
		"abilita": ["bonus_tiro", "mira", "portata", "acrobatiche", "angolato", "inceppamenti"],
		"bio": "Divenne Asso il 10 ottobre 1916. All'inizio del 1917 ha già 16 vittorie, ovvero 760 punti esperienza."},
	"guynemer": {"nome": "Georges Guynemer", "titolo": "Guynemer", "nazione": "francia", "esperienza": 1200, "abbattimenti": 26,
		"abilita": ["bonus_tiro", "mira", "portata", "acrobatiche", "angolato", "stabilita", "tallonare"],
		"bio": "Prima vittoria come osservatore il 19 luglio 1915, Asso il 3 febbraio 1916. All'inizio del 1917 questo «diavolo» colleziona la sua 26ª vittoria."},
	"boelcke": {"nome": "Oswald Boelcke", "titolo": "Boelcke", "nazione": "germania", "esperienza": 1900, "abbattimenti": 40, "bonus_tiro": 2,
		"abilita": ["bonus_tiro", "mira", "portata", "acrobatiche", "angolato", "stabilita", "tallonare", "evasive", "inceppamenti"],
		"bio": "Asso il 17 ottobre 1915, morto in una collisione con un aereo della sua squadriglia il 28 ottobre 1916. 40 vittorie: tutte le abilità, ma a +2!"},
	"madon": {"nome": "Georges Madon", "titolo": "Madon", "nazione": "francia", "esperienza": 800, "abbattimenti": 17,
		"abilita": ["bonus_tiro", "mira", "portata", "acrobatiche", "angolato", "inceppamenti"],
		"bio": "Asso il 22 agosto 1916. Agli inizi del 1917 ha già 17 vittorie: le stesse abilità di von Richthofen."},
	"heurtaux": {"nome": "Alfred Heurtaux", "titolo": "Heurtaux", "nazione": "francia", "esperienza": 770, "abbattimenti": 16,
		"abilita": ["acrobatiche", "evasive", "tallonare", "bonus_tiro", "mira", "angolato", "portata"],
		"bio": "Prima vittoria il 4 maggio 1916, Asso il 2 agosto 1916. Agli inizi del 1917 ha 16 vittorie."},
	"collishaw": {"nome": "Raymond Collishaw", "titolo": "Collishaw", "nazione": "inghilterra", "esperienza": 105, "abbattimenti": 2,
		"abilita": ["acrobatiche"],
		"bio": "Guida il Black Flight del X Aereosquadrone della Royal Navy, triplani dipinti di nero: il suo si chiama Black Maria."},
	"hawker": {"nome": "Lanoe Hawker", "titolo": "Maggiore Hawker", "nazione": "inghilterra", "esperienza": 400, "abbattimenti": 7,
		"abilita": ["acrobatiche", "bonus_tiro", "stabilita", "tallonare"], "bio": "Asso inglese abbattuto da Richthofen il 23 novembre 1916."},
	"udet": {"nome": "Ernst Udet", "titolo": "Udet", "nazione": "germania", "esperienza": 250, "abbattimenti": 5,
		"abilita": ["acrobatiche", "bonus_tiro"], "bio": "Giovane Asso con appena 5 vittorie."},
}

const ELENCO := [
	{"id": "guynemer", "titolo": "Prima vittoria di Guynemer",
		"testo": "Per prendere confidenza con il sistema di gioco: un Bristol F.2B contro un Halberstadt CL.II. Sono armati solo della mitragliatrice posteriore dell'osservatore; il CL.II ha una penalità di -3 (è armato di una carabina)."},
	{"id": "americani", "titolo": "Primi combattimenti dell'aviazione americana",
		"testo": "18 aprile 1917 (data del regolamento): il primo combattimento sotto le coccarde americane. Due Nieuport 28 affrontano un Albatros D.Va e un Pfalz D.III."},
	{"id": "hawker", "titolo": "Asso contro Asso: Richthofen e Hawker",
		"testo": "23 novembre 1916: von Richthofen affronta l'Asso inglese Maggiore Hawker su un Nieuport (senza la manovra 15). Richthofen vola su un Albatros D.III."},
	{"id": "meute", "titolo": "La Meute, 26 giugno 1917",
		"testo": "Attirato in un vile tranello, Guynemer su uno Spad VII affronta da solo due Albatros D.III. Ne abbatte due e raggiunge così la 28ª e la 29ª vittoria. Guynemer ha un bonus al tiro di +2."},
	{"id": "udet", "titolo": "Asso contro Asso: Guynemer e Udet",
		"testo": "Guynemer incontra Udet, giovane Asso con appena 5 vittorie. Durante il combattimento Udet inceppò le mitragliatrici, ma Guynemer lo lasciò scappare..."},
]

## Ingombro di partenza: Tedeschi in alto (righe basse), Alleati in basso
static func posizioni(lato: String, n: int, vicino := false) -> Array:
	var out = []
	var righe = [1, 0, 2] if lato == "G" else [12, 13, 11]
	if vicino:
		righe = [3, 2, 4] if lato == "G" else [10, 11, 9]
	var i = 0
	for r in righe:
		# colonne centrali (assiali): q = colonna_offset - (r - (r&1))/2
		var cols = [4, 2, 6, 3, 5, 1, 7, 0, 8]
		for cof in cols:
			if out.size() >= n:
				return out
			var q: int = cof - (r - (r & 1)) / 2
			var prua = (1 if i % 2 == 0 else 2) if lato == "G" else (5 if i % 2 == 0 else 4)
			out.append({"q": q, "r": r, "prua": prua})
			i += 1
	return out

static func pilota_asso(k: String, extra := {}) -> Dictionary:
	var a: Dictionary = ASSI[k].duplicate(true)
	a.merge(extra, true)
	return a

## Costruisce uno scenario. squadre: {"G": "ia"|"umano", "A": ...}
static func costruisci(id: String, controlli: Dictionary, opzioni: Dictionary) -> Regole:
	var S = Regole.nuova(opzioni)
	var R = Regole.new(S)
	S["scenario"] = id
	var cg: String = controlli.get("G", "ia")
	var ca: String = controlli.get("A", "umano")
	match id:
		"guynemer":
			var pg = posizioni("G", 1, true)[0]
			var pa = posizioni("A", 1, true)[0]
			R.aggiungi("halberstadt", "germania", pg["q"], pg["r"], pg["prua"], 2, {"nome": "Pilota tedesco", "solo_osservatore": true, "carabina": -3, "novellino": false}, cg)
			R.aggiungi("bristol", "inghilterra", pa["q"], pa["r"], pa["prua"], 2, {"nome": "Georges Guynemer (osservatore)", "solo_osservatore": true}, ca)
		"americani":
			var pg = posizioni("G", 2, true)
			var pa = posizioni("A", 2, true)
			R.aggiungi("albatros_d5", "germania", pg[0]["q"], pg[0]["r"], pg[0]["prua"], 2, {"nome": "Leutnant Weber"}, cg)
			R.aggiungi("pfalz_d3", "germania", pg[1]["q"], pg[1]["r"], pg[1]["prua"], 2, {"nome": "Vizefeldwebel Kraus"}, cg)
			R.aggiungi("nieuport28", "usa", pa[0]["q"], pa[0]["r"], pa[0]["prua"], 2, {"nome": "Douglas Campbell"}, ca)
			R.aggiungi("nieuport28", "usa", pa[1]["q"], pa[1]["r"], pa[1]["prua"], 2, {"nome": "Alan Winslow"}, ca)
		"hawker":
			var pg = posizioni("G", 1, true)[0]
			var pa = posizioni("A", 1, true)[0]
			var rich = pilota_asso("richthofen")
			rich["abilita"] = ["bonus_tiro", "mira", "acrobatiche", "angolato"]
			R.aggiungi("albatros_d3", "germania", pg["q"], pg["r"], pg["prua"], 3, rich, cg)
			R.aggiungi("nieuport17", "inghilterra", pa["q"], pa["r"], pa["prua"], 3, pilota_asso("hawker", {"escluse": ["15S3", "15D3"]}), ca)
		"meute":
			var pg = posizioni("G", 2, true)
			var pa = posizioni("A", 1, true)[0]
			R.aggiungi("albatros_d3", "germania", pg[0]["q"], pg[0]["r"], pg[0]["prua"], 3, {"nome": "Leutnant Böhme"}, cg)
			R.aggiungi("albatros_d3", "germania", pg[1]["q"], pg[1]["r"], pg[1]["prua"], 3, {"nome": "Leutnant Bauer"}, cg)
			R.aggiungi("spad7", "francia", pa["q"], pa["r"], pa["prua"], 3, pilota_asso("guynemer", {"bonus_tiro": 2}), ca)
		"udet":
			var pg = posizioni("G", 1, true)[0]
			var pa = posizioni("A", 1, true)[0]
			R.aggiungi("albatros_d3", "germania", pg["q"], pg["r"], pg["prua"], 3, pilota_asso("udet"), cg)
			R.aggiungi("spad7", "francia", pa["q"], pa["r"], pa["prua"], 3, pilota_asso("guynemer"), ca)
	R.avvia()
	return R

## Schermaglia libera. aerei: [{tipo, nazione, controllo, pilota, quota}]
static func schermaglia(aerei: Array, opzioni: Dictionary, vicino := true) -> Regole:
	var S = Regole.nuova(opzioni)
	var R = Regole.new(S)
	S["scenario"] = "libera"
	var g = aerei.filter(func(x): return Dati.NAZIONI[x["nazione"]]["lato"] == "G")
	var a = aerei.filter(func(x): return Dati.NAZIONI[x["nazione"]]["lato"] == "A")
	var pg = posizioni("G", g.size(), vicino)
	var pa = posizioni("A", a.size(), vicino)
	for i in g.size():
		var x: Dictionary = g[i]
		R.aggiungi(x["tipo"], x["nazione"], pg[i]["q"], pg[i]["r"], pg[i]["prua"], int(x.get("quota", 2)), x.get("pilota", {"nome": "Pilota"}), x.get("controllo", "ia"))
	for i in a.size():
		var x: Dictionary = a[i]
		R.aggiungi(x["tipo"], x["nazione"], pa[i]["q"], pa[i]["r"], pa[i]["prua"], int(x.get("quota", 2)), x.get("pilota", {"nome": "Pilota"}), x.get("controllo", "ia"))
	R.avvia()
	return R
