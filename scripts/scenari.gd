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
	"voss": {"nome": "Werner Voss", "titolo": "Voss", "nazione": "germania", "esperienza": 1300, "abbattimenti": 48,
		"abilita": ["acrobatiche", "evasive", "bonus_tiro", "mira", "angolato", "tallonare", "stabilita"], "bio": "48 vittorie a vent'anni: il pilota più acrobatico della Germania."},
	"mccudden": {"nome": "James McCudden", "titolo": "McCudden", "nazione": "inghilterra", "esperienza": 500, "abbattimenti": 7,
		"abilita": ["tallonare", "bonus_tiro", "mira", "inceppamenti"], "bio": "Ex meccanico, pilota metodico della 56ª Squadriglia."},
	"rhys_davids": {"nome": "Arthur Rhys Davids", "titolo": "Rhys Davids", "nazione": "inghilterra", "esperienza": 400, "abbattimenti": 19,
		"abilita": ["bonus_tiro", "angolato", "acrobatiche"], "bio": "Ventenne, fu lui ad abbattere Werner Voss."},
	"brown": {"nome": "Roy Brown", "titolo": "Capitano Brown", "nazione": "inghilterra", "esperienza": 300, "abbattimenti": 9,
		"abilita": ["bonus_tiro", "acrobatiche"], "bio": "Canadese, comandante di squadriglia del 209° Squadrone."},
	"may": {"nome": "Wilfrid May", "titolo": "Wop May", "nazione": "inghilterra", "esperienza": 10, "abbattimenti": 0, "novellino": true,
		"abilita": [], "bio": "Novellino al primo combattimento: inseguito dal Barone Rosso."},
	"wolff": {"nome": "Hans Joachim Wolff", "titolo": "Wolff", "nazione": "germania", "esperienza": 200, "abbattimenti": 10,
		"abilita": ["bonus_tiro"], "bio": "Gregario di Richthofen nella Jasta 11."},
	"mannock": {"nome": "Edward Mannock", "titolo": "Mick Mannock", "nazione": "inghilterra", "esperienza": 1500, "abbattimenti": 61,
		"abilita": ["tallonare", "bonus_tiro", "mira", "portata", "angolato", "evasive"], "bio": "Il più grande Asso britannico, maestro della tattica di squadriglia."},
	"rickenbacker": {"nome": "Eddie Rickenbacker", "titolo": "Rickenbacker", "nazione": "usa", "esperienza": 600, "abbattimenti": 10,
		"abilita": ["bonus_tiro", "mira", "acrobatiche", "inceppamenti"], "bio": "Ex pilota d'auto da corsa, Asso degli Asso americani."},
	"nungesser": {"nome": "Charles Nungesser", "titolo": "Nungesser", "nazione": "francia", "esperienza": 900, "abbattimenti": 21,
		"abilita": ["acrobatiche", "bonus_tiro", "mira", "evasive"], "bio": "Ferito più volte, volava con un teschio dipinto sulla fusoliera."},
	"lowenhardt": {"nome": "Erich Löwenhardt", "titolo": "Löwenhardt", "nazione": "germania", "esperienza": 1100, "abbattimenti": 40,
		"abilita": ["bonus_tiro", "mira", "tallonare", "acrobatiche", "angolato"], "bio": "Comandante della Jasta 10, terzo Asso tedesco della guerra."},
	"immelmann": {"nome": "Max Immelmann", "titolo": "Immelmann", "nazione": "germania", "esperienza": 500, "abbattimenti": 15,
		"abilita": ["acrobatiche", "bonus_tiro", "mira"], "bio": "L'«Aquila di Lilla», inventore della virata che porta il suo nome."},
}

## Altri scenari storici (descritti con i dati): immagine, data (mese da gennaio 1917, negativo = 1916), aerei
const STORICI := [
	{"id": "immelmann", "titolo": "Il flagello dei Fokker", "data": "Giugno 1916", "img": 3,
		"testo": "I monoplani Fokker con la mitragliatrice sincronizzata dominano il cielo. Max Immelmann affronta due Airco DH.2 inglesi, il caccia a elica spingente nato per fermarlo.",
		"G": [["fokker_e3", "immelmann", 2], ["fokker_e3", "Leutnant Mulzer", 2]], "A": [["dh2", "Capt. Andrews", 2], ["dh2", "Lt. Saundby", 2]]},
	{"id": "aprile", "titolo": "Aprile di sangue", "data": "Aprile 1917", "img": 6,
		"testo": "Il mese più nero del Royal Flying Corps. Gli Albatros della Jasta 11 di von Richthofen piombano dal sole su una pattuglia di Bristol e Sopwith Pup.",
		"G": [["albatros_d3", "richthofen", 3], ["albatros_d3", "wolff", 3], ["albatros_d3", "Leutnant Schäfer", 3]],
		"A": [["bristol", "Capt. Robinson", 2], ["bristol", "Lt. Warren", 2], ["pup", "Lt. Pratt", 2]]},
	{"id": "nungesser", "titolo": "Il teschio di Nungesser", "data": "Maggio 1917", "img": 4,
		"testo": "Charles Nungesser, con il suo Nieuport 17 dipinto con il teschio, sorprende due Albatros D.III sopra le Fiandre.",
		"G": [["albatros_d3", "Leutnant Hoppe", 2], ["albatros_d3", "Vizefeldwebel Groos", 2]], "A": [["nieuport17", "nungesser", 3]]},
	{"id": "scorta", "titolo": "Scorta al ricognitore", "data": "Settembre 1917", "img": 7,
		"testo": "Un Airco DH.4 deve fotografare le retrovie tedesche, scortato da due S.E.5a. Tre Albatros D.V salgono a intercettarlo: il ricognitore deve tornare a casa.",
		"G": [["albatros_d5", "Leutnant Bongartz", 2], ["albatros_d5", "Leutnant Weiss", 2], ["albatros_d5", "Vizefeldwebel Rahn", 3]],
		"A": [["dh4", "Lt. Hart", 2], ["se5a", "Capt. Bowman", 3], ["se5a", "Lt. Muspratt", 3]]},
	{"id": "voss", "titolo": "L'ultima battaglia di Werner Voss", "data": "23 settembre 1917", "img": 4,
		"testo": "Voss, con il suo triplano Fokker, tiene testa da solo per dieci minuti a sette S.E.5 della 56ª Squadriglia, i migliori piloti inglesi. Qui affronta McCudden, Rhys Davids e un loro gregario.",
		"G": [["fokker_dr1", "voss", 2]], "A": [["se5a", "mccudden", 3], ["se5a", "rhys_davids", 2], ["se5a", "Lt. Muspratt", 2]]},
	{"id": "barone", "titolo": "L'ultimo volo del Barone Rosso", "data": "21 aprile 1918", "img": 9,
		"testo": "Sopra la Somme il novellino Wop May viene inseguito a bassa quota da von Richthofen. Roy Brown accorre in suo aiuto con il suo Camel, mentre Wolff tenta di coprire il suo comandante.",
		"G": [["fokker_dr1", "richthofen", 1], ["fokker_dr1", "wolff", 2]], "A": [["camel", "may", 1], ["camel", "brown", 2]]},
	{"id": "circo", "titolo": "Il Circo Volante", "data": "Marzo 1918", "img": 9,
		"testo": "L'offensiva di primavera: i triplani colorati del Jagdgeschwader I si scontrano in una mischia furibonda con le squadriglie di Camel.",
		"G": [["fokker_dr1", "Leutnant Weiss", 2], ["fokker_dr1", "Leutnant Kempf", 2], ["fokker_dr1", "Leutnant Steinhäuser", 3], ["pfalz_d3", "Vizefeldwebel Scholz", 2]],
		"A": [["camel", "Capt. Le Boutillier", 2], ["camel", "Lt. Mellersh", 2], ["camel", "Lt. Taylor", 3], ["camel", "Lt. Mackenzie", 2]]},
	{"id": "rickenbacker", "titolo": "Gli Spad del 94° Aero Squadron", "data": "Settembre 1918", "img": 2,
		"testo": "Eddie Rickenbacker guida i suoi Spad XIII contro una formazione di Fokker D.VII sopra Saint-Mihiel.",
		"G": [["fokker_d7", "Leutnant Koepsch", 3], ["fokker_d7", "Leutnant Hübner", 3], ["fokker_d7", "Vizefeldwebel Klein", 2]],
		"A": [["spad13", "rickenbacker", 3], ["spad13", "Lt. Chambers", 3], ["spad13", "Lt. Taylor", 2]]},
	{"id": "mannock", "titolo": "La tattica di Mannock", "data": "Luglio 1918", "img": 6,
		"testo": "Mick Mannock porta i suoi S.E.5a all'attacco dall'alto contro Fokker D.VII e un Pfalz D.XII guidati da Löwenhardt.",
		"G": [["fokker_d7", "lowenhardt", 3], ["fokker_d7", "Leutnant Wenzl", 2], ["pfalz_d12", "Vizefeldwebel Lux", 2]],
		"A": [["se5a", "mannock", 4], ["se5a", "Lt. Inglis", 3], ["se5a", "Lt. Clements", 3]]},
	{"id": "nero", "titolo": "Il Volo Nero", "data": "Giugno 1917", "img": 4,
		"testo": "I triplani neri di Raymond Collishaw («Black Maria») contro una pattuglia di Albatros D.III della Jasta 11.",
		"G": [["albatros_d3", "Leutnant Allmenröder", 3], ["albatros_d3", "Leutnant Krefft", 3]],
		"A": [["triplane", "collishaw", 3], ["triplane", "Flt Sub-Lt. Reid", 3]]},
]

## Situazioni per il generatore di scenari
const SITUAZIONI := {
	"incontro": {"nome": "Incontro fra pattuglie", "img": 1, "testo": "Due pattuglie sbucano dalle nuvole e si trovano faccia a faccia."},
	"sole": {"nome": "Imboscata dal sole", "img": 6, "testo": "Una parte attacca dall'alto, con il sole alle spalle: parte più alta e più vicina."},
	"scorta": {"nome": "Scorta al ricognitore", "img": 7, "testo": "Un biposto da ricognizione con la sua scorta incontra i caccia nemici."},
	"mischia": {"nome": "Grande mischia", "img": 9, "testo": "Squadriglie intere si scontrano: tutti partono vicini e alla stessa quota."},
	"inseguimento": {"nome": "Inseguimento a bassa quota", "img": 3, "testo": "Un aereo isolato rientra a quota bassa, i nemici gli sono addosso."},
}

const ELENCO := [
	{"id": "guynemer", "img": 1, "data": "19 luglio 1915", "titolo": "Prima vittoria di Guynemer",
		"testo": "Per prendere confidenza con il sistema di gioco: un Bristol F.2B contro un Halberstadt CL.II. Sono armati solo della mitragliatrice posteriore dell'osservatore; il CL.II ha una penalità di -3 (è armato di una carabina)."},
	{"id": "americani", "img": 2, "data": "18 aprile 1918", "titolo": "Primi combattimenti dell'aviazione americana",
		"testo": "18 aprile 1917 (data del regolamento): il primo combattimento sotto le coccarde americane. Due Nieuport 28 affrontano un Albatros D.Va e un Pfalz D.III."},
	{"id": "hawker", "img": 3, "data": "23 novembre 1916", "titolo": "Asso contro Asso: Richthofen e Hawker",
		"testo": "23 novembre 1916: von Richthofen affronta l'Asso inglese Maggiore Hawker su un Nieuport (senza la manovra 15). Richthofen vola su un Albatros D.III."},
	{"id": "meute", "img": 4, "data": "26 giugno 1917", "titolo": "La Meute, 26 giugno 1917",
		"testo": "Attirato in un vile tranello, Guynemer su uno Spad VII affronta da solo due Albatros D.III. Ne abbatte due e raggiunge così la 28ª e la 29ª vittoria. Guynemer ha un bonus al tiro di +2."},
	{"id": "udet", "img": 5, "data": "1917", "titolo": "Asso contro Asso: Guynemer e Udet",
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
		_:
			for d in STORICI:
				if d["id"] == id:
					_da_dati(R, d, cg, ca)
	R.avvia()
	return R

static func storico(id: String) -> Dictionary:
	for d in STORICI:
		if d["id"] == id:
			return d
	return {}

static func _pilota_da(nome: String) -> Dictionary:
	if ASSI.has(nome):
		return pilota_asso(nome)
	return {"nome": nome}

static func _naz_di(tipo: String, lato: String) -> String:
	var n: Array = Dati.aerei[tipo]["nazioni"]
	return n[0]

static func _da_dati(R: Regole, d: Dictionary, cg: String, ca: String) -> void:
	for lato in ["G", "A"]:
		var l: Array = d[lato]
		var pos = posizioni(lato, l.size(), true)
		for i in l.size():
			var x: Array = l[i]
			var pil = _pilota_da(x[1])
			var naz: String = ASSI[x[1]]["nazione"] if ASSI.has(x[1]) else _naz_di(x[0], lato)
			if lato == "A" and d["id"] == "rickenbacker":
				naz = "usa"
			R.aggiungi(x[0], naz, pos[i]["q"], pos[i]["r"], pos[i]["prua"], int(x[2]), pil, cg if lato == "G" else ca)

## Generatore di scenari: epoca (mese, 0 = gennaio 1917; da -12 = 1916), aerei per parte, situazione
static func genera(mese: int, n_g: int, n_a: int, situazione: String, rn: RandomNumberGenerator) -> Dictionary:
	var g = []
	var a = []
	var prende = func(nazioni: Array, n: int, biposto_primo: bool) -> Array:
		var out = []
		var tipi = Dati.ordine_aerei.filter(func(t):
			var x: Dictionary = Dati.aerei[t]
			return int(x["disponibile_dal"]) <= mese and x["nazioni"].any(func(z): return z in nazioni))
		# preferisce gli aerei più recenti dell'epoca
		tipi.sort_custom(func(p, q): return int(Dati.aerei[p]["disponibile_dal"]) > int(Dati.aerei[q]["disponibile_dal"]))
		var caccia = tipi.filter(func(t): return int(Dati.aerei[t]["osservatore"]) == 0)
		var biposti = tipi.filter(func(t): return int(Dati.aerei[t]["osservatore"]) > 0)
		for i in n:
			var lista: Array = biposti if (biposto_primo and i == 0 and not biposti.is_empty()) else caccia
			if lista.is_empty():
				lista = tipi
			var k = mini(lista.size() - 1, int(abs(rn.randfn(0.0, 2.2))))
			out.append(lista[k])
		return out
	var naz_a = ["inghilterra", "francia"] + (["usa"] if mese >= 15 else [])
	var scorta_a = situazione == "scorta" and rn.randf() < 0.5
	var tg = prende.call(["germania"], n_g, situazione == "scorta" and not scorta_a)
	var ta = prende.call(naz_a, n_a, scorta_a)
	var nomi_g = ["Leutnant Wolff", "Vizefeldwebel Hahn", "Leutnant Bauer", "Oberleutnant Kraus", "Leutnant Schulz", "Unteroffizier Lang", "Leutnant Weiss", "Leutnant Kempf"]
	var nomi_a = ["Capt. Barker", "Lt. Ball", "Lt. Collins", "Sous-Lt. Fonck", "Sgt. Dorme", "Lt. Campbell", "Lt. Meissner", "Capt. Bishop"]
	var quote = {"G": 2, "A": 2}
	var vicino = true
	match situazione:
		"sole":
			var chi = "G" if rn.randf() < 0.5 else "A"
			quote[chi] = 3
		"inseguimento":
			quote = {"G": 1, "A": 1}
		"incontro":
			vicino = false
	var lista = []
	for i in tg.size():
		lista.append({"tipo": tg[i], "nazione": "germania", "quota": quote["G"] + (1 if rn.randf() < 0.2 else 0),
			"pilota": _pilota_casuale(nomi_g[i % nomi_g.size()], rn)})
	for i in ta.size():
		var possibili: Array = Dati.aerei[ta[i]]["nazioni"].filter(func(z): return z in naz_a)
		lista.append({"tipo": ta[i], "nazione": possibili[rn.randi_range(0, possibili.size() - 1)], "quota": quote["A"] + (1 if rn.randf() < 0.2 else 0),
			"pilota": _pilota_casuale(nomi_a[i % nomi_a.size()], rn)})
	for x in lista:
		x["quota"] = clampi(int(x["quota"]), 0, int(Dati.aerei[x["tipo"]]["quota_max"]))
	return {"aerei": lista, "vicino": vicino, "situazione": situazione, "mese": mese}

static func _pilota_casuale(nome: String, rn: RandomNumberGenerator) -> Dictionary:
	var r = rn.randf()
	if r < 0.25:
		return {"nome": nome, "novellino": true}
	if r < 0.85:
		return {"nome": nome}
	return {"nome": nome, "abbattimenti": 6, "abilita": ["bonus_tiro", "mira", "acrobatiche"]}

static func nome_mese(m: int) -> String:
	var mesi = ["Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno", "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"]
	return "%s %d" % [mesi[posmod(m, 12)], 1917 + int(floor(m / 12.0))]

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
