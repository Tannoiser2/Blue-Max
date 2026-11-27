class_name Regole
extends RefCounted
## Motore delle regole di Blue Max (regolamento italiano Stratelibri 1993).
## Lo stato della partita è un Dictionary serializzabile in JSON (salvataggi, rete, replay).
## Le funzioni non toccano la grafica: restituiscono eventi da animare.

const FASI := ["Tallonamento", "Scelta della manovra", "Consumo di carburante", "Movimento", "Combattimento",
	"Risoluzione dei danni", "Recupero", "Incidenti", "Danni da incendio", "Spegnimento incendi e fumo"]

var S: Dictionary = {}
var rng = RandomNumberGenerator.new()
var celle = {}   # Vector2i -> true (esagoni della mappa)
var riga_min = 0
var riga_max = 13
var riga_trincea = 6.5   # sopra: territorio tedesco, sotto: alleato

# --------------------------------------------------------------------------- impostazione
func _init(stato: Dictionary = {}) -> void:
	for c in Dati.mappa.get("celle", []):
		celle[Vector2i(int(c[0]), int(c[1]))] = true
	if not stato.is_empty():
		S = interi(stato)
		rng.seed = int(S.get("seme", 1))
		rng.state = int(S.get("rng", 1))

## Dopo un passaggio in JSON i numeri tornano decimali: rimette interi quelli che lo sono
static func interi(v: Variant) -> Variant:
	if v is Dictionary:
		for k in v.keys():
			v[k] = interi(v[k])
		return v
	if v is Array:
		for i in v.size():
			v[i] = interi(v[i])
		return v
	if v is float and v == floor(v) and absf(v) < 1e15:
		return int(v)
	return v

static func nuova(opzioni: Dictionary) -> Dictionary:
	return {"turno": 1, "fase": 0, "aerei": [], "opzioni": opzioni, "seme": int(opzioni.get("seme", randi())),
		"rng": 0, "diario": [], "finita": false, "vincitore": "", "storia": [], "pedine": {}}

func avvia() -> void:
	rng.seed = int(S["seme"])
	S["rng"] = rng.state
	_prepara_pedine()

func _salva_rng() -> void:
	S["rng"] = rng.state

func d6() -> int:
	var v = rng.randi_range(1, 6)
	_salva_rng()
	return v

func annota(t: String, tipo := "") -> void:
	S["diario"].append({"t": S["turno"], "testo": t, "tipo": tipo})

## Aggiunge un aereo. pilota: {nome, abilita[], esperienza, abbattimenti, novellino}
func aggiungi(tipo: String, nazione: String, q: int, r: int, prua: int, quota: int, pilota: Dictionary, controllo := "ia") -> Dictionary:
	var t: Dictionary = Dati.aerei[tipo]
	var lato: String = Dati.NAZIONI[nazione]["lato"]
	var mitra = []
	for i in int(t["mitragliatrici"]):
		var lw: bool = i == 0 and int(t["lewis_pilota"]) == 1
		mitra.append({"lewis": lw, "inceppata": false, "distrutta": false, "caricatori": _caricatori(t) if lw else []})
	var oss = {}
	if int(t["osservatore"]) > 0:
		oss = {"presente": true, "vivo": true, "ferito": 0, "n": int(t["osservatore"]), "lewis": bool(t["lewis_osservatore"]),
			"inceppata": false, "caricatori": _caricatori(t) if bool(t["lewis_osservatore"]) else [], "nome": "Osservatore", "novellino": true}
	var a = {
		"id": S["aerei"].size(), "tipo": tipo, "nazione": nazione, "lato": lato, "controllo": controllo,
		"pilota": pilota.get("nome", "Pilota"), "abilita": pilota.get("abilita", []),
		"novellino": bool(pilota.get("novellino", false)), "asso": int(pilota.get("abbattimenti", 0)) >= 5,
		"bonus_tiro": int(pilota.get("bonus_tiro", 1 if "bonus_tiro" in pilota.get("abilita", []) else 0)),
		"q": q, "r": r, "prua": posmod(prua, 6), "quota": quota,
		"carb": int(t["carburante"]), "ali": int(t["ali"]), "fus": int(t["fusoliera"]), "coda": int(t["coda"]) + (1 if S["opzioni"].get("coda_piu_uno", false) else 0), "motore": int(t["motore"]),
		"mitra": mitra, "oss": oss, "stato": "volo", "fuoco": false, "fumo": false,
		"timone": {}, "ferito_lento": false, "ferito_avanti": false, "no_acro": false, "no_veloce": false,
		"ultima": "", "manovra": "", "quota_cambio": 0, "obbligo": 0, "stallo": false, "vite": false,
		"spari_prec": {}, "spari": {}, "colpito_da": {}, "abbattimenti": 0, "danni_turno": [], "scaduto_quota_max": false,
		"carabina": int(pilota.get("carabina", 0)), "solo_osservatore": bool(pilota.get("solo_osservatore", false)),
		"escluse": pilota.get("escluse", []), "colore": pilota.get("colore", ""), "esperienza": int(pilota.get("esperienza", 0)),
		"giocatore": pilota.get("giocatore", ""), "uid": pilota.get("uid", ""), "danni_visti": [],
	}
	if a["solo_osservatore"]:
		for m in a["mitra"]:
			m["distrutta"] = true
	S["aerei"].append(a)
	return a

func _caricatori(t: Dictionary) -> Array:
	var c = []
	for i in int(t["caricatori_lewis"]):
		c.append(5)
	return c

func aereo(id: int) -> Dictionary:
	return S["aerei"][id]

func tipo(a: Dictionary) -> Dictionary:
	return Dati.aerei[a["tipo"]]

func pos(a: Dictionary) -> Vector2i:
	return Vector2i(int(a["q"]), int(a["r"]))

func in_gioco(a: Dictionary) -> bool:
	return a["stato"] in ["volo", "vite", "planata"]

func attivi() -> Array:
	return S["aerei"].filter(func(a): return in_gioco(a))

func nemici(a: Dictionary) -> Array:
	return attivi().filter(func(b): return b["lato"] != a["lato"])

func ha(a: Dictionary, ab: String) -> bool:
	if ab in ["mira", "portata"] and not a["asso"]:
		return false
	return ab in a["abilita"]

func stabilita(a: Dictionary) -> String:
	var s: String = tipo(a)["stabilita"]
	if ha(a, "stabilita"):
		s = {"C": "B", "B": "A", "A": "A"}[s]
	return s

func quota_max(a: Dictionary) -> int:
	var t = tipo(a)
	var m = int(t["quota_max"])
	return m

# --------------------------------------------------------------------------- pedine-danno
func _prepara_pedine() -> void:
	var rosse = range(36)
	var blu = range(36)
	if S["opzioni"].get("togli_pilota_ucciso", true):
		# la pedina con "Pilota ucciso" su entrambi i lati
		rosse.erase(20)
		blu.erase(20)
	S["pedine"] = {"rosse": rosse, "blu": blu}

func pesca(colore: String) -> Dictionary:
	var mazzo: Array = S["pedine"]["rosse" if colore == "R" else "blu"]
	var i: int = mazzo[rng.randi_range(0, mazzo.size() - 1)]
	_salva_rng()
	var p: Dictionary = (Dati.danni["rosse"] if colore == "R" else Dati.danni["blu"])[i].duplicate()
	p["colore"] = colore
	p["indice"] = i
	return p

# --------------------------------------------------------------------------- tallonamento
## Restituisce {tallonatore_id: tallonato_id}
func calcola_tallonamenti() -> Dictionary:
	var out = {}
	for a in attivi():
		a["tallona"] = -1
		a["tallonato_da"] = []
	for a in attivi():
		if a["stato"] != "volo" or a["fuoco"] or a["fumo"]:
			continue
		var migliore = -1
		var dmig = 99
		for b in attivi():
			if b["id"] == a["id"]:
				continue
			if not puo_tallonare(a, b):
				continue
			var d = Hex.distanza(pos(a), pos(b))
			# si preferisce il nemico più vicino
			var peso = d + (0 if b["lato"] != a["lato"] else 10)
			if peso < dmig:
				dmig = peso
				migliore = b["id"]
		if migliore >= 0:
			out[a["id"]] = migliore
			a["tallona"] = migliore
			aereo(migliore)["tallonato_da"].append(a["id"])
	return out

func puo_tallonare(a: Dictionary, b: Dictionary) -> bool:
	if absi(int(a["quota"]) - int(b["quota"])) > 1:
		return false
	if b["lato"] != a["lato"]:
		if a["novellino"]:
			return false
		if ha(b, "evasive") and not a["asso"]:
			return false
	var pa = pos(a)
	var pb = pos(b)
	var maxd = 4 if ha(a, "tallonare") else 3
	if pa == pb:
		var ua = Dati.codice(a["ultima"]) if a["ultima"] != "" else {"vel": 0}
		var ub = Dati.codice(b["ultima"]) if b["ultima"] != "" else {"vel": 0}
		return int(a["prua"]) == int(b["prua"]) and int(ua["vel"]) < int(ub["vel"])
	return Hex.in_arco_frontale(pa, a["prua"], pb, maxd) and Hex.in_arco_posteriore(pb, b["prua"], pa, 3)

## Ordine in cui gli aerei scelgono: chi è tallonato sceglie prima di chi lo tallona.
## Nelle catene circolari si tira un dado: il più basso rivela per primo.
func ordine_scelta() -> Array:
	var ids = attivi().map(func(a): return a["id"])
	var fatti = []
	var guard = 0
	while fatti.size() < ids.size() and guard < 50:
		guard += 1
		var avanzato = false
		for id in ids:
			if id in fatti:
				continue
			var a = aereo(id)
			var t: int = a.get("tallona", -1)
			if t < 0 or t in fatti or not (t in ids):
				fatti.append(id)
				avanzato = true
		if not avanzato:
			# catena circolare: dado
			var resto = ids.filter(func(x): return not (x in fatti))
			var minimo = 99
			var chi: int = resto[0]
			for id in resto:
				var d = d6()
				if d < minimo:
					minimo = d
					chi = id
			fatti.append(chi)
			annota("Catena di tallonamenti circolare: %s rivela per primo." % nome(aereo(chi)))
	return fatti

func nome(a: Dictionary) -> String:
	return "%s (%s)" % [a["pilota"], tipo(a)["nome"]]

# --------------------------------------------------------------------------- manovre consentite
## Elenco delle manovre consentite con il cambio di quota: [{codice, quota: -1/0/+1, fuga, carb}]
func manovre_possibili(a: Dictionary) -> Array:
	var out = []
	if a["stato"] == "vite" or a["vite"]:
		return [{"codice": "0A2", "quota": 0, "carb": 0, "fuga": false, "forzata": "vite"}]
	if a["stallo"]:
		return [{"codice": "1A1", "quota": 0, "carb": 1, "fuga": false, "forzata": "stallo"}]
	var t = tipo(a)
	var planata: bool = a["stato"] == "planata" or int(a["carb"]) <= 0 or int(a["motore"]) <= 0
	var ult: Dictionary = Dati.codice(a["ultima"]) if a["ultima"] != "" else {}
	for c in t["manovre"]:
		if c in a["escluse"]:
			continue
		var g = Dati.geometria(c)
		var vel: int = g["vel"]
		if planata and not (g["n"] in [2, 9]):
			continue
		if not ult.is_empty() and not planata:
			if absi(vel - int(ult["vel"])) > 1:
				continue
			if g["non_ripetibile"] and Dati.manovre[str(ult["n"])]["non_ripetibile"]:
				continue
		if g["acrobatica"]:
			if a["novellino"] or a["no_acro"] or a["fuoco"]:
				continue
			if not ha(a, "acrobatiche"):
				var stessa = a["ultima"] == c and not g["non_ripetibile"]
				if not stessa and (ult.is_empty() or not (int(ult["n"]) in [2, 3, 4, 5])):
					continue
		if a["no_veloce"] and vel >= 3:
			continue
		if not a["timone"].is_empty() and int(a["timone"].get("turni", 0)) > 0:
			if g["dir"] != a["timone"]["dir"]:
				continue
		if a["ferito_lento"] and not ult.is_empty():
			if vel != maxi(1, int(ult["vel"]) - 1):
				continue
		if a["ferito_avanti"] and g["dir"] != "A":
			continue
		var fuga = _esito_percorso(a, g)
		if fuga == "fuori":
			continue
		for dq in [0, 1, -1]:
			var obb: int = a["obbligo"]
			if obb != 0 and dq != obb:
				continue
			# chi plana scende di quota a ogni turno (a quota Molto Bassa atterra appena può)
			if planata and int(a["quota"]) > 0 and dq != -1:
				continue
			if dq == 1:
				if g["acrobatica"] or vel < 2 or planata or vel >= int(t["velocita_max"]):
					continue
				if int(a["quota"]) >= quota_max(a) and not (tipo(a)["quota_piu"] and int(a["quota"]) < 4):
					continue
				if a["scaduto_quota_max"] and int(a["quota"]) + 1 >= quota_max(a) and not tipo(a)["quota_piu"]:
					continue
			if dq == -1:
				if vel < 2 and not planata:
					continue
				if int(a["quota"]) == 0:
					# picchiata dalla quota Molto Bassa: solo per atterrare dopo una manovra Avanti
					if ult.is_empty() or ult["dir"] != "A":
						continue
			var carb = vel + dq
			if planata:
				carb = 0
			elif S["opzioni"].get("carburante_meta", false):
				carb = int(ceil(carb / 2.0))
			if not planata and carb > int(a["carb"]):
				continue
			out.append({"codice": c, "quota": dq, "carb": carb, "fuga": fuga == "fuga"})
	if out.is_empty():
		# nessuna manovra possibile: stallo
		return [{"codice": "1A1", "quota": 0, "carb": mini(1, int(a["carb"])), "fuga": false, "forzata": "stallo"}]
	return out

## Controlla dove porta la manovra: "ok", "fuga" (esce dal lato giusto), "fuori" (esce altrove: vietata)
func _esito_percorso(a: Dictionary, g: Dictionary) -> String:
	var p = pos(a)
	for s in g["passi"]:
		p = Hex.vicino(p, int(a["prua"]) + int(s))
		if not celle.has(p):
			if (a["lato"] == "G" and p.y < riga_min) or (a["lato"] == "A" and p.y > riga_max):
				return "fuga"
			return "fuori"
	return "ok"

## Percorso esagono per esagono (per animazioni e anteprime): [{q,r,prua}]
func percorso(a: Dictionary, c: String) -> Array:
	var g = Dati.geometria(c)
	var p = pos(a)
	var out = [{"q": p.x, "r": p.y, "prua": a["prua"]}]
	if c == "0A2":
		return out
	var f: int = a["prua"]
	for s in g["passi"]:
		var d = f + int(s)
		p = Hex.vicino(p, d)
		out.append({"q": p.x, "r": p.y, "prua": posmod(d, 6)})
	out.append({"q": p.x, "r": p.y, "prua": posmod(f + int(g["prua"]), 6)})
	return out

# --------------------------------------------------------------------------- scelta, carburante, movimento
## scelte: id -> {codice, quota}
func applica_scelte(scelte: Dictionary) -> void:
	for a in attivi():
		var s: Dictionary = scelte.get(a["id"], scelte.get(str(a["id"]), {}))
		if s.is_empty():
			var p = manovre_possibili(a)
			s = p[0]
		a["manovra"] = s["codice"]
		a["quota_cambio"] = int(s.get("quota", 0))
		if a["stallo"] and a["manovra"] == "1A1":
			pass

func fase_carburante() -> void:
	for a in attivi():
		if a["stato"] == "vite":
			a["carb"] = maxi(0, int(a["carb"]) - 2)
			continue
		var g = Dati.codice(a["manovra"])
		var c: int = int(g["vel"]) + int(a["quota_cambio"])
		if S["opzioni"].get("carburante_meta", false):
			c = int(ceil(c / 2.0))
		if a["stato"] == "planata":
			c = 0
		a["carb"] = maxi(0, int(a["carb"]) - maxi(c, 0))

## Muove tutti gli aerei. Restituisce gli eventi: [{id, percorso, quota_da, quota_a, esito}]
func fase_movimento() -> Array:
	var eventi = []
	for a in attivi():
		var c: String = a["manovra"]
		var per = percorso(a, c)
		var qda: int = a["quota"]
		var esito = ""
		var fin: Dictionary = per[-1]
		a["q"] = fin["q"]
		a["r"] = fin["r"]
		a["prua"] = fin["prua"]
		if not celle.has(pos(a)):
			a["stato"] = "fuggito"
			esito = "fuga"
			annota("%s esce dalla mappa e rientra alla base." % nome(a), "fuga")
		var dq: int = a["quota_cambio"]
		if esito == "" and dq != 0:
			var nq: int = int(a["quota"]) + dq
			if nq < 0:
				var ult = Dati.codice(a["ultima"]) if a["ultima"] != "" else {"dir": ""}
				if ult["dir"] == "A" and a["stato"] != "vite":
					a["stato"] = "atterrato"
					a["quota"] = 0
					esito = "atterraggio"
					_atterraggio(a)
				else:
					_schianto(a)
					esito = "schianto"
			elif nq > quota_max(a) and not (tipo(a)["quota_piu"] and nq <= 4):
				a["stallo"] = true
				esito = "stallo"
				annota("%s non riesce a salire e va in stallo." % nome(a), "avviso")
			else:
				if int(a["quota"]) == quota_max(a) and nq < quota_max(a) and not tipo(a)["quota_piu"]:
					a["scaduto_quota_max"] = true
				a["quota"] = nq
		# effetti della manovra
		var n = Dati.codice(c)["n"]
		if n == 1 and esito == "" and a["stato"] == "volo":
			# stallo in rallentamento: rischio di avvitamento
			var soglia = 4 if a["novellino"] else 5
			if d6() >= soglia:
				_entra_vite(a, "stallo")
				esito = "vite"
		if a["stallo"] and c == "1A1":
			a["stallo"] = false
		# ricarica della Lewis con le manovre 2, 3, 4 o 5
		if n in [2, 3, 4, 5]:
			for m in a["mitra"]:
				if m["lewis"] and not m["caricatori"].is_empty() and int(m["caricatori"][0]) < 5:
					m["ricarica"] = true
		a["ultima"] = c
		a["obbligo"] = 0
		eventi.append({"id": a["id"], "percorso": per, "quota_da": qda, "quota_a": a["quota"], "esito": esito, "codice": c})
	if S["opzioni"].get("collisioni", false):
		_collisioni()
	return eventi

## Regola opzionale: aerei nello stesso esagono e alla stessa quota tirano un dado; chi fa lo stesso numero si scontra
## e prende due pedine-danno rosse.
func _collisioni() -> void:
	var gruppi = {}
	for a in attivi():
		var k = "%d,%d,%d" % [int(a["q"]), int(a["r"]), int(a["quota"])]
		if not gruppi.has(k):
			gruppi[k] = []
		gruppi[k].append(a)
	for k in gruppi:
		var l: Array = gruppi[k]
		if l.size() < 2:
			continue
		var dadi = {}
		for a in l:
			var d = d6()
			if not dadi.has(d):
				dadi[d] = []
			dadi[d].append(a)
		for d in dadi:
			if dadi[d].size() >= 2:
				for a in dadi[d]:
					annota("%s si scontra in volo!" % nome(a), "abbattuto")
					for i in 2:
						var p = pesca("R")
						p["fronte"] = false
						p["retro"] = false
						a["danni_turno"].append(p)

func _entra_vite(a: Dictionary, perche: String) -> void:
	if a["stato"] == "vite":
		return
	a["stato"] = "vite"
	a["vite"] = true
	annota("%s entra in avvitamento (%s)!" % [nome(a), perche], "vite")

func _schianto(a: Dictionary) -> void:
	a["stato"] = "abbattuto"
	a["quota"] = 0
	annota("%s si schianta al suolo!" % nome(a), "abbattuto")
	_accredita(a)

func _atterraggio(a: Dictionary) -> void:
	var amico = (a["lato"] == "G" and float(a["r"]) < riga_trincea) or (a["lato"] == "A" and float(a["r"]) > riga_trincea)
	if amico:
		annota("%s atterra in territorio amico." % nome(a), "fuga")
	else:
		a["stato"] = "catturato"
		annota("%s atterra in territorio nemico." % nome(a), "avviso")

func territorio_amico(a: Dictionary) -> bool:
	return (a["lato"] == "G" and float(a["r"]) < riga_trincea) or (a["lato"] == "A" and float(a["r"]) > riga_trincea)

# --------------------------------------------------------------------------- combattimento
## Le armi con cui l'aereo a può sparare al bersaglio b: [{arma: "pilota"/"osservatore", distanza, ...}]
func puo_sparare(a: Dictionary, b: Dictionary) -> Array:
	var out = []
	if not in_gioco(a) or not in_gioco(b) or a["id"] == b["id"]:
		return out
	if a["stato"] == "vite":
		return out
	if absi(int(a["quota"]) - int(b["quota"])) > 1:
		return out
	var pa = pos(a)
	var pb = pos(b)
	# mitragliatrici del pilota
	if not a["fuoco"] and _armi_pilota_pronte(a) > 0:
		var dist = -1
		if pa == pb:
			var ua = Dati.codice(a["ultima"])
			var ub = Dati.codice(b["ultima"])
			if int(a["prua"]) == int(b["prua"]) and int(ua["vel"]) < int(ub["vel"]):
				dist = 0
		else:
			var d = Hex.su_linea(pa, a["prua"], pb, 3)
			if d > 0 and not _bloccato(pa, a["prua"], d, a, b):
				dist = d
		if dist >= 0:
			out.append({"arma": "pilota", "distanza": dist})
	# osservatore: tutto l'arco posteriore tranne l'esagono subito dietro (salvo bersaglio più in alto)
	var o: Dictionary = a["oss"]
	var oss_ok = true
	if S["opzioni"].get("osservatore_limitato", false) and a["ultima"] != "":
		oss_ok = int(Dati.codice(a["ultima"])["n"]) in [1, 2, 3, 4, 5, 6, 7, 12, 13, 18, 19, 25, 26]
	if oss_ok and not o.is_empty() and o["presente"] and o["vivo"] and int(o["ferito"]) <= 0 and not o["inceppata"] and _oss_munizioni(a):
		if pa != pb and Hex.in_arco_posteriore(pa, a["prua"], pb, 3):
			var dietro = Hex.vicino(pa, int(a["prua"]) + 3)
			if not (pb == dietro and int(b["quota"]) <= int(a["quota"])):
				out.append({"arma": "osservatore", "distanza": Hex.distanza(pa, pb)})
	return out

func _bloccato(pa: Vector2i, prua: int, d: int, a: Dictionary, b: Dictionary) -> bool:
	var lin = Hex.linea(pa, prua, d - 1)
	for c in lin:
		for x in attivi():
			if x["id"] != a["id"] and x["id"] != b["id"] and pos(x) == c:
				return true
	return false

func _armi_pilota_pronte(a: Dictionary) -> int:
	var n = 0
	for m in a["mitra"]:
		if m["distrutta"] or m["inceppata"]:
			continue
		if m["lewis"] and (m.get("ricarica", false) or m["caricatori"].is_empty() or int(m["caricatori"][0]) <= 0):
			continue
		n += 1
	return n

func _oss_munizioni(a: Dictionary) -> bool:
	var o: Dictionary = a["oss"]
	if not o["lewis"]:
		return true
	return not o["caricatori"].is_empty() and int(o["caricatori"][0]) > 0

## Raffiche consentite (la Lewis ha bisogno di caselle nel caricatore)
func raffiche_possibili(a: Dictionary, arma: String) -> Array:
	var out = []
	var colpi = {"corta": 1, "media": 2, "lunga": 3}
	for r in ["corta", "media", "lunga"]:
		var ok = true
		if arma == "osservatore":
			var o: Dictionary = a["oss"]
			if o["lewis"]:
				var serve: int = colpi[r] * (2 if int(o["n"]) >= 2 and o["caricatori"].size() >= 2 else 1)
				ok = _lewis_caselle(o["caricatori"]) >= colpi[r]
		else:
			pass
		if ok:
			out.append(r)
	return out

func _lewis_caselle(car: Array) -> int:
	return int(car[0]) if not car.is_empty() else 0

## Valore di fuoco e modificatori (per l'anteprima e la risoluzione)
func valore_fuoco(a: Dictionary, b: Dictionary, arma: String, raffica: String) -> Dictionary:
	var armi = puo_sparare(a, b)
	var info = {}
	for x in armi:
		if x["arma"] == arma:
			info = x
	if info.is_empty():
		return {"valore": 0, "mod": [], "ok": false}
	var dist: int = info["distanza"]
	var col = {3: 0, 2: 1, 1: 2, 0: 3}
	var dcalc = dist
	if arma == "pilota" and ha(a, "portata") and dist >= 2:
		dcalc = dist - 1
	var k: int = col[clampi(dcalc, 0, 3)]
	var M: Dictionary = Dati.comb["mod"]
	var v: int = int(Dati.comb["base"][k])
	var mod = [["Distanza %d" % dist, v]]
	var agg = func(nomem: String, chiave: String):
		var x: int = int(M[chiave][k])
		if x != 0:
			mod.append([nomem, x])
		return x
	v += agg.call("Raffica " + raffica, raffica)
	var corretta = S["opzioni"].get("tabella_corretta", false)
	if corretta and stabilita(a) == "C":
		var xc: int = [0, 0, 0, 1][k]
		if xc != 0:
			mod.append(["Stabilità C", xc])
		v += xc
	else:
		v += agg.call("Stabilità " + stabilita(a), "stab_" + stabilita(a))
	if Dati.codice(b["ultima"])["n"] == 1 and b["ultima"] != "":
		v += agg.call("Bersaglio in stallo", "stallo")
	var vel = int(Dati.codice(a["ultima"])["vel"]) if a["ultima"] != "" else 0
	if vel >= 3:
		v += agg.call("Velocità %d" % vel, "veloce")
	var singola = false
	if arma == "pilota":
		singola = _armi_pilota_pronte(a) <= 1
	else:
		singola = int(a["oss"]["n"]) <= 1
	if singola:
		v += agg.call("Una sola mitragliatrice", "singola")
	var angolata = _angolata(a, b, arma)
	if angolata and not ha(a, "angolato"):
		v += agg.call("Posizione angolata", "angolata")
	var prec: Dictionary = a["spari_prec"]
	if prec.get(str(b["id"]), "") == arma:
		v += agg.call("Bersaglio già inquadrato", "inquadrato")
	if arma == "pilota" and int(a.get("tallona", -1)) == int(b["id"]):
		v += agg.call("Bersaglio tallonato", "tallonato")
	if corretta:
		if int(b["quota"]) != int(a["quota"]):
			var xq: int = [-4, -3, -2, -1][k]
			v += xq
			mod.append(["Quota diversa", xq])
	elif int(b["quota"]) < int(a["quota"]):
		v += agg.call("Bersaglio più in basso", "inferiore")
	if S["opzioni"].get("tiro_vite", false) and b["stato"] == "vite":
		v -= 2
		mod.append(["Bersaglio in avvitamento", -2])
		if not angolata and not ha(a, "angolato"):
			v -= 1
			mod.append(["Avvitamento: sempre angolato", -1])
	if arma == "pilota" and ha(a, "mira"):
		v += 1
		mod.append(["Mira (Asso)", 1])
	if int(a["carabina"]) != 0 and arma == "osservatore":
		v += int(a["carabina"])
		mod.append(["Carabina", int(a["carabina"])])
	return {"valore": v, "mod": mod, "ok": true, "distanza": dist, "angolata": angolata}

func _angolata(a: Dictionary, b: Dictionary, arma: String) -> bool:
	var pa = pos(a)
	var pb = pos(b)
	var stessa_dir = int(a["prua"]) == int(b["prua"]) or posmod(int(a["prua"]) - int(b["prua"]), 6) == 3
	if arma == "pilota":
		return not stessa_dir
	# osservatore: non angolato solo se spara dritto in coda e il bersaglio punta verso di lui o dalla parte opposta
	var dritto = Hex.su_linea(pa, int(a["prua"]) + 3, pb, 3) > 0
	return not (dritto and stessa_dir)

## attacchi: [{da, a, arma, raffica}] — risolti tutti insieme; restituisce gli eventi per l'animazione
func fase_combattimento(attacchi: Array) -> Array:
	var eventi = []
	for x in S["aerei"]:
		x["spari"] = {}
	var per_bersaglio = {}
	for at in attacchi:
		var a = aereo(int(at["da"]))
		var b = aereo(int(at["a"]))
		var vf = valore_fuoco(a, b, at["arma"], at["raffica"])
		if not vf["ok"]:
			continue
		var dado = d6()
		var dado_eff = dado
		if at["arma"] == "pilota" and int(a["bonus_tiro"]) > 0 and dado < 6:
			dado_eff = mini(6, dado + int(a["bonus_tiro"]))
		var valore = clampi(int(vf["valore"]), 0, 15)
		var ris = [0, 0]
		if valore > 0:
			ris = Dati.comb["risultati"][dado_eff - 1][valore - 1]
		_consuma_munizioni(a, at["arma"], at["raffica"])
		a["spari"][str(b["id"])] = at["arma"]
		if at["raffica"] == "lunga":
			a["raffica_lunga_" + at["arma"]] = true
		# obblighi di quota per raffiche media e lunga
		if at["raffica"] != "corta" and at["arma"] == "pilota":
			if int(b["quota"]) > int(a["quota"]):
				a["obbligo"] = 1
			elif int(b["quota"]) < int(a["quota"]):
				a["obbligo"] = -1
		var ev = {"da": a["id"], "a": b["id"], "arma": at["arma"], "raffica": at["raffica"], "valore": int(vf["valore"]),
			"mod": vf["mod"], "dado": dado, "dado_eff": dado_eff, "blu": ris[0], "rosse": ris[1], "pedine": []}
		if not per_bersaglio.has(b["id"]):
			per_bersaglio[b["id"]] = []
		per_bersaglio[b["id"]].append(ev)
		eventi.append(ev)
		annota("%s spara a %s: raffica %s, valore %d, dado %d -> %s" % [nome(a), nome(b), at["raffica"], int(vf["valore"]), dado_eff, _testo_ris(ris)], "fuoco")
		if ris[0] + ris[1] > 0:
			b["colpito_da"][str(a["id"])] = S["turno"]
	# pesca delle pedine: tutte le blu poi tutte le rosse, per ogni attacco, alla fine
	for bid in per_bersaglio:
		var b = aereo(int(bid))
		for ev in per_bersaglio[bid]:
			var a = aereo(int(ev["da"]))
			for i in int(ev["blu"]):
				var p = pesca("B")
				p["da"] = a["id"]
				p["fronte"] = _da_fronte(a, b)
				p["retro"] = _da_retro(a, b)
				ev["pedine"].append(p)
				b["danni_turno"].append(p)
			for i in int(ev["rosse"]):
				var p = pesca("R")
				p["da"] = a["id"]
				p["fronte"] = _da_fronte(a, b)
				p["retro"] = _da_retro(a, b)
				ev["pedine"].append(p)
				b["danni_turno"].append(p)
	for x in S["aerei"]:
		x["spari_prec"] = x["spari"].duplicate()
	return eventi

func _testo_ris(r: Array) -> String:
	if r[0] + r[1] == 0:
		return "mancato"
	var t = []
	if r[0] > 0:
		t.append("%d blu" % r[0])
	if r[1] > 0:
		t.append("%d rosse" % r[1])
	return ", ".join(t)

func _da_fronte(a: Dictionary, b: Dictionary) -> bool:
	return int(a["quota"]) == int(b["quota"]) and Hex.in_arco_frontale(pos(b), b["prua"], pos(a), 3)

func _da_retro(a: Dictionary, b: Dictionary) -> bool:
	if pos(a) == pos(b):
		return true
	return int(a["quota"]) == int(b["quota"]) and Hex.in_arco_posteriore(pos(b), b["prua"], pos(a), 3)

func _consuma_munizioni(a: Dictionary, arma: String, raffica: String) -> void:
	var colpi: int = {"corta": 1, "media": 2, "lunga": 3}[raffica]
	if arma == "pilota":
		for m in a["mitra"]:
			if m["lewis"] and not m["distrutta"] and not m["inceppata"]:
				_scala_caricatore(m["caricatori"], colpi)
	else:
		var o: Dictionary = a["oss"]
		if o["lewis"]:
			_scala_caricatore(o["caricatori"], colpi)
			if int(o["n"]) >= 2 and o["caricatori"].size() > 1:
				_scala_caricatore(o["caricatori"], 0)

func _scala_caricatore(car: Array, n: int) -> void:
	if car.is_empty():
		return
	car[0] = maxi(0, int(car[0]) - n)

# --------------------------------------------------------------------------- risoluzione dei danni
## Applica i danni del turno. Restituisce eventi: [{id, testo, abbattuto}]
func fase_danni() -> Array:
	var eventi = []
	for b in attivi():
		var colpi_ali_coda = false
		for p in b["danni_turno"]:
			var r = applica_pedina(b, p)
			if r["ali_coda"]:
				colpi_ali_coda = true
			eventi.append({"id": b["id"], "pedina": p, "testo": r["testo"]})
			if not in_gioco(b):
				break
		b["danni_visti"] = b["danni_turno"].duplicate()
		b["danni_turno"] = []
		if in_gioco(b) and b["stato"] != "vite" and colpi_ali_coda:
			var soglia = 4 if b["novellino"] else 5
			if d6() >= soglia:
				_entra_vite(b, "ali o coda danneggiate")
				eventi.append({"id": b["id"], "testo": "in avvitamento!"})
	return eventi

## Applica una pedina-danno all'aereo b. Gestisce colpi frontali/posteriori alla stessa quota.
func applica_pedina(b: Dictionary, p: Dictionary) -> Dictionary:
	var ali_coda = false
	var testo = Dati.testo_pedina(p)
	var spec: String = p.get("spec", "")
	var fronte: bool = p.get("fronte", false)
	var retro: bool = p.get("retro", false)
	var coda: int = int(p.get("coda", 0))
	var motore: int = int(p.get("motore", 0))
	if fronte and coda > 0:
		motore += coda
		coda = 0
	if retro and motore > 0:
		coda += motore
		motore = 0
	if fronte and spec == "timone":
		spec = "motore_colpito"
	if retro and spec == "motore_colpito":
		spec = "timone_avanti"
	if int(p.get("ala", 0)) > 0:
		b["ali"] = maxi(0, int(b["ali"]) - int(p["ala"]))
		ali_coda = true
	if int(p.get("fusoliera", 0)) > 0:
		b["fus"] = maxi(0, int(b["fus"]) - int(p["fusoliera"]))
	if coda > 0:
		b["coda"] = maxi(0, int(b["coda"]) - coda)
		ali_coda = true
	if motore > 0:
		b["motore"] = maxi(0, int(b["motore"]) - motore)
	match spec:
		"esplosione":
			_distrutto(b, "il serbatoio esplode")
			return {"ali_coda": false, "testo": testo}
		"pilota_ucciso":
			_distrutto(b, "il pilota è ucciso")
			return {"ali_coda": false, "testo": testo}
		"serbatoio":
			b["carb"] = maxi(0, int(b["carb"]) - int(p["carb"]))
		"timone":
			if b["timone"].is_empty() or int(b["timone"].get("turni", 0)) <= 0:
				b["timone"] = {"dir": p["dir"], "turni": int(p["turni"])}
		"timone_avanti":
			b["timone"] = {"dir": "A", "turni": 3}
		"oss_ucciso":
			if not b["oss"].is_empty():
				b["oss"]["vivo"] = false
				annota("L'osservatore di %s è ucciso." % nome(b), "avviso")
		"oss_ferito":
			if not b["oss"].is_empty():
				b["oss"]["ferito"] = 3
		"fuoco":
			if p.has("da"):
				b["incendiato_da"] = int(p["da"])
			b["fuoco"] = true
			b["fumo"] = false
			annota("%s prende fuoco!" % nome(b), "fuoco")
		"fumo":
			if not b["fuoco"]:
				b["fumo"] = true
				annota("%s perde fumo." % nome(b), "avviso")
		"ferito_avanti":
			if b["timone"].is_empty() or int(b["timone"].get("turni", 0)) <= 0:
				b["ferito_avanti"] = true
		"ferito_lento":
			b["ferito_lento"] = true
		"ala_lacerata", "montante":
			b["no_acro"] = true
		"ala_lacerata_veloce", "motore_colpito":
			b["no_veloce"] = true
		"mitragliatrice":
			var buone = []
			for i in b["mitra"].size():
				if not b["mitra"][i]["distrutta"]:
					buone.append(i)
			if not buone.is_empty():
				b["mitra"][buone[rng.randi_range(0, buone.size() - 1)]]["distrutta"] = true
				_salva_rng()
	if int(b["ali"]) <= 0 or int(b["fus"]) <= 0 or int(b["coda"]) <= 0:
		if b["stato"] != "vite" or not b.get("vite_finale", false):
			b["vite_finale"] = true
			_entra_vite(b, "struttura distrutta")
	if (int(b["motore"]) <= 0 or int(b["carb"]) <= 0) and b["stato"] == "volo":
		b["stato"] = "planata"
	return {"ali_coda": ali_coda, "testo": testo}

func _distrutto(b: Dictionary, perche: String) -> void:
	b["stato"] = "abbattuto"
	annota("%s è abbattuto: %s!" % [nome(b), perche], "abbattuto")
	_accredita(b)

## L'abbattimento va a chi ha colpito l'aereo in questo turno (non per gli incendi)
func _accredita(b: Dictionary) -> void:
	var dati = false
	for k in b["colpito_da"]:
		if int(b["colpito_da"][k]) == int(S["turno"]):
			var a = aereo(int(k))
			if a["stato"] == "abbattuto":
				continue
			a["abbattimenti"] = int(a["abbattimenti"]) + 1
			dati = true
			annota("Abbattimento accreditato a %s." % a["pilota"], "vittoria")
	if not dati and b.has("incendiato_da") and (b["fuoco"] or b.get("vite_finale", false)):
		var a = aereo(int(b["incendiato_da"]))
		if a["stato"] != "abbattuto":
			a["abbattimenti"] = int(a["abbattimenti"]) + 1
			annota("Abbattimento accreditato a %s, che aveva appiccato l'incendio." % a["pilota"], "vittoria")

# --------------------------------------------------------------------------- recupero, incidenti, incendi
func fase_recupero() -> Array:
	var eventi = []
	for a in attivi():
		var g = Dati.codice(a["ultima"]) if a["ultima"] != "" else {"dir": "", "n": 0}
		var avanti_non_acro: bool = g["dir"] == "A" and int(g["n"]) < 27 and a["stato"] != "vite"
		for m in a["mitra"]:
			if m["inceppata"] and not m["distrutta"] and avanti_non_acro:
				var d = d6()
				if d >= (3 if ha(a, "inceppamenti") else 4):
					m["inceppata"] = false
					eventi.append({"id": a["id"], "testo": "mitragliatrice disinceppata"})
			if m.get("ricarica", false):
				m["ricarica"] = false
				m["caricatori"].pop_front()
				eventi.append({"id": a["id"], "testo": "nuovo caricatore della Lewis"})
		var o: Dictionary = a["oss"]
		if not o.is_empty() and o["vivo"]:
			if o["inceppata"]:
				if d6() >= 4:
					o["inceppata"] = false
			if o["lewis"] and not o["caricatori"].is_empty() and int(o["caricatori"][0]) <= 0:
				o["caricatori"].pop_front()
				eventi.append({"id": a["id"], "testo": "l'osservatore cambia caricatore"})
			if int(o["ferito"]) > 0:
				o["ferito"] = int(o["ferito"]) - 1
		if a["stato"] == "vite" and not a.get("vite_finale", false):
			var d = d6()
			if d >= (4 if a["novellino"] else 3):
				a["stato"] = "planata" if (int(a["motore"]) <= 0 or int(a["carb"]) <= 0) else "volo"
				a["vite"] = false
				a["prua"] = d6() - 1
				a["ultima"] = "2A2"
				annota("%s esce dall'avvitamento." % nome(a), "recupero")
				eventi.append({"id": a["id"], "testo": "esce dall'avvitamento", "recupero": true})
		# effetti che durano un solo turno
		a["ferito_lento"] = false
		a["ferito_avanti"] = false
		if not a["timone"].is_empty():
			a["timone"]["turni"] = int(a["timone"]["turni"]) - 1
			if int(a["timone"]["turni"]) <= 0:
				a["timone"] = {}
	return eventi

func fase_incidenti() -> Array:
	var eventi = []
	for a in attivi():
		if a.get("raffica_lunga_pilota", false):
			for m in a["mitra"]:
				if not m["distrutta"] and not m["inceppata"]:
					var d = d6()
					if d >= (6 if ha(a, "inceppamenti") else 5):
						m["inceppata"] = true
						eventi.append({"id": a["id"], "testo": "mitragliatrice inceppata!", "inceppata": true})
						annota("Una mitragliatrice di %s si inceppa." % nome(a), "avviso")
		if a.get("raffica_lunga_osservatore", false) and not a["oss"].is_empty():
			if d6() >= 5:
				a["oss"]["inceppata"] = true
				eventi.append({"id": a["id"], "testo": "arma dell'osservatore inceppata!"})
		a.erase("raffica_lunga_pilota")
		a.erase("raffica_lunga_osservatore")
		if a["stato"] == "vite":
			a["quota"] = int(a["quota"]) - 1
			eventi.append({"id": a["id"], "testo": "perde quota in avvitamento", "quota": a["quota"]})
			if int(a["quota"]) < 0:
				a["quota"] = 0
				_schianto(a)
				eventi.append({"id": a["id"], "testo": "si schianta al suolo!", "schianto": true})
	return eventi

func fase_incendi() -> Array:
	var eventi = []
	for a in attivi():
		if a["fuoco"]:
			var p = pesca("B")
			p["fronte"] = false
			p["retro"] = false
			var r = applica_pedina(a, p)
			eventi.append({"id": a["id"], "pedina": p, "testo": "Incendio: " + r["testo"]})
	return eventi

func fase_spegnimento() -> Array:
	var eventi = []
	for a in attivi():
		var n = int(Dati.codice(a["ultima"])["n"]) if a["ultima"] != "" else 0
		if a["fuoco"]:
			var d = d6()
			if d >= (4 if n in [8, 16, 17] else 5):
				a["fuoco"] = false
				annota("%s riesce a spegnere l'incendio." % nome(a), "recupero")
				eventi.append({"id": a["id"], "testo": "incendio spento"})
		elif a["fumo"]:
			var d = d6()
			if d == 6:
				a["fumo"] = false
				eventi.append({"id": a["id"], "testo": "il fumo si dirada"})
			elif d == 1:
				a["fumo"] = false
				a["fuoco"] = true
				annota("Il motore di %s prende fuoco!" % nome(a), "fuoco")
				eventi.append({"id": a["id"], "testo": "il fumo diventa fuoco!"})
	return eventi

## Fine turno: controlla la vittoria e passa al turno seguente
func fine_turno() -> void:
	var g = attivi().filter(func(a): return a["lato"] == "G").size()
	var al = attivi().filter(func(a): return a["lato"] == "A").size()
	if g == 0 or al == 0:
		S["finita"] = true
		var abb_g = S["aerei"].filter(func(a): return a["lato"] == "G" and a["stato"] in ["abbattuto", "catturato"]).size()
		var abb_a = S["aerei"].filter(func(a): return a["lato"] == "A" and a["stato"] in ["abbattuto", "catturato"]).size()
		if abb_g > abb_a:
			S["vincitore"] = "A"
		elif abb_a > abb_g:
			S["vincitore"] = "G"
		else:
			S["vincitore"] = "pari"
		annota("Fine del combattimento.", "fine")
	S["turno"] = int(S["turno"]) + 1

## Istantanea per il replay (solo i dati che servono a ridisegnare)
func istantanea() -> Dictionary:
	var l = []
	for a in S["aerei"]:
		l.append({"id": a["id"], "q": a["q"], "r": a["r"], "prua": a["prua"], "quota": a["quota"], "stato": a["stato"],
			"fuoco": a["fuoco"], "fumo": a["fumo"]})
	return {"turno": S["turno"], "aerei": l}
