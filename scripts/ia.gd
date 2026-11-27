class_name IA
extends RefCounted
## Pilota guidato dal computer.
## Ogni turno prova tutte le sue manovre contro un campione di manovre possibili di ogni nemico
## (pesate, per l'Asso, con quello che farebbe un buon pilota) e sceglie quella con il punteggio migliore.
## Principi presi dai consigli dei giocatori esperti: stare in coda al nemico e fuori dal suo muso,
## sparare da vicino e in linea, tenere la quota, non finire contro i bordi, conservare carburante,
## non rischiare le acrobazie senza motivo, rientrare quando l'aereo è a pezzi.

const LIVELLI := {"recluta": {"campioni": 6, "rumore": 4.0, "risposta": false},
	"veterano": {"campioni": 14, "rumore": 1.0, "risposta": false},
	"asso": {"campioni": 24, "rumore": 0.2, "risposta": true}}

var R: Regole
var livello = "veterano"
var rng = RandomNumberGenerator.new()
static var EV := []   # danno atteso per valore di fuoco 0..15

func _init(regole: Regole, liv := "veterano") -> void:
	R = regole
	livello = liv
	rng.seed = int(regole.S.get("seme", 7)) * 31 + regole.S["turno"]
	if EV.is_empty():
		EV.append(0.0)
		for v in range(1, 16):
			var s = 0.0
			for d in 6:
				var r: Array = Dati.comb["risultati"][d][v - 1]
				s += float(r[0]) * 1.0 + float(r[1]) * 2.6
			EV.append(s / 6.0)

static func danno_atteso(v: int) -> float:
	return EV[clampi(v, 0, 15)] if EV.size() > 0 else 0.0

## Posizione finale di un aereo dopo una manovra (senza toccare lo stato)
func finale(a: Dictionary, m: Dictionary) -> Dictionary:
	var per = R.percorso(a, m["codice"])
	var f: Dictionary = per[-1]
	return {"p": Vector2i(int(f["q"]), int(f["r"])), "prua": int(f["prua"]), "quota": clampi(int(a["quota"]) + int(m["quota"]), 0, 4),
		"vel": int(Dati.codice(m["codice"])["vel"]), "fuga": m.get("fuga", false), "codice": m["codice"]}

## Valore di fuoco stimato da una posizione all'altra (raffica media)
func stima_fuoco(da: Dictionary, a_: Dictionary, chi: Dictionary, stab: String, tallona := false) -> float:
	if absi(int(da["quota"]) - int(a_["quota"])) > 1:
		return 0.0
	var dist = -1
	if da["p"] == a_["p"]:
		if da["prua"] == a_["prua"] and da["vel"] < a_["vel"]:
			dist = 0
	else:
		dist = Hex.su_linea(da["p"], da["prua"], a_["p"], 3)
		if dist == 0:
			dist = -1
	if dist < 0:
		return 0.0
	var k: int = {3: 0, 2: 1, 1: 2, 0: 3}[dist]
	var M: Dictionary = Dati.comb["mod"]
	var v: int = int(Dati.comb["base"][k]) + int(M["media"][k]) + int(M["stab_" + stab][k])
	if da["vel"] >= 3:
		v += int(M["veloce"][k])
	if chi.get("singola", false):
		v += int(M["singola"][k])
	var stessa: bool = da["prua"] == a_["prua"] or posmod(da["prua"] - a_["prua"], 6) == 3
	if not stessa:
		v += int(M["angolata"][k])
	if tallona:
		v += int(M["tallonato"][k])
	if int(a_["quota"]) < int(da["quota"]):
		v += int(M["inferiore"][k])
	return danno_atteso(v)

func _salute(a: Dictionary) -> float:
	var t = R.tipo(a)
	var s = minf(float(a["ali"]) / float(t["ali"]), float(a["fus"]) / float(t["fusoliera"]))
	s = minf(s, float(a["coda"]) / float(t["coda"]))
	return s

func _puo_sparare_pilota(a: Dictionary) -> bool:
	return not a["fuoco"] and R._armi_pilota_pronte(a) > 0

## Punteggio di una situazione (io dopo la mia manovra, nemico dopo la sua)
func valuta(a: Dictionary, me: Dictionary, b: Dictionary, lui: Dictionary) -> float:
	var s = 0.0
	var stab = R.stabilita(a)
	var stab_b = R.stabilita(b)
	if _puo_sparare_pilota(a):
		s += stima_fuoco(me, lui, {"singola": R._armi_pilota_pronte(a) <= 1}, stab) * 10.0
	if _puo_sparare_pilota(b):
		s -= stima_fuoco(lui, me, {"singola": R._armi_pilota_pronte(b) <= 1}, stab_b) * 11.0
	# osservatori (arco posteriore)
	if not a["oss"].is_empty() and a["oss"]["vivo"] and Hex.in_arco_posteriore(me["p"], me["prua"], lui["p"], 3) and absi(me["quota"] - lui["quota"]) <= 1:
		s += 6.0
	if not b["oss"].is_empty() and b["oss"]["vivo"] and Hex.in_arco_posteriore(lui["p"], lui["prua"], me["p"], 3) and absi(me["quota"] - lui["quota"]) <= 1:
		s -= 7.0
	# tallonamento al turno dopo
	var d = Hex.distanza(me["p"], lui["p"])
	if absi(me["quota"] - lui["quota"]) <= 1:
		if Hex.in_arco_frontale(me["p"], me["prua"], lui["p"], 3) and Hex.in_arco_posteriore(lui["p"], lui["prua"], me["p"], 3):
			s += 9.0
		if Hex.in_arco_frontale(lui["p"], lui["prua"], me["p"], 3) and Hex.in_arco_posteriore(me["p"], me["prua"], lui["p"], 3):
			s -= 10.0
		# averlo davanti (anche non in coda) è comunque buono
		if Hex.in_arco_frontale(me["p"], me["prua"], lui["p"], 4):
			s += 2.5
		if Hex.in_arco_frontale(lui["p"], lui["prua"], me["p"], 3):
			s -= 2.0
	# nuvole: chi ci entra è difficile da colpire; utile soprattutto quando le cose vanno male
	if _in_nuvola_pos(me):
		s += 2.0 + (4.0 if _salute(a) < 0.5 else 0.0)
		# distanza: si cerca il nemico, ma senza stargli davanti al muso
	s -= absf(d - 2.0) * 0.6
	# quota: meglio stare alla sua quota o una sopra
	var dq: int = me["quota"] - lui["quota"]
	if dq == 0 or dq == 1:
		s += 1.0
	elif absi(dq) > 1:
		s -= 1.5 * (absi(dq) - 1)
	return s

func scegli_manovra(a: Dictionary, info: Dictionary = {}) -> Dictionary:
	var P: Dictionary = LIVELLI.get(livello, LIVELLI["veterano"])
	var mie = R.manovre_possibili(a)
	if mie.size() == 1:
		return mie[0]
	var nem = R.nemici(a)
	var salute = _salute(a)
	var t = R.tipo(a)
	var in_fuga = salute < 0.3 or int(a["carb"]) < 6 or (R._armi_pilota_pronte(a) == 0 and (a["oss"].is_empty() or not a["oss"]["vivo"]))
	# campioni delle manovre nemiche
	var campioni = {}
	for b in nem:
		var lm = R.manovre_possibili(b)
		if info.has(str(b["id"])):
			var inf: Dictionary = info[str(b["id"])]
			var filt = lm.filter(func(m): return Dati.codice(m["codice"])["dir"] == inf.get("dir", Dati.codice(m["codice"])["dir"]) and int(m["quota"]) == int(inf.get("quota", m["quota"])))
			if not filt.is_empty():
				lm = filt
		var fin = []
		if P["risposta"] and lm.size() > 1:
			# l'Asso immagina che il nemico scelga bene contro la sua posizione attuale
			var io_ora = {"p": R.pos(a), "prua": int(a["prua"]), "quota": int(a["quota"]), "vel": 2}
			var pes = []
			for m in lm:
				var f = finale(b, m)
				pes.append([valuta(b, f, a, io_ora), f])
			pes.sort_custom(func(x, y): return x[0] > y[0])
			for i in mini(int(P["campioni"]), pes.size()):
				fin.append(pes[i][1])
			# un po' di imprevedibilità
			for i in 4:
				fin.append(finale(b, lm[rng.randi_range(0, lm.size() - 1)]))
		else:
			for i in mini(int(P["campioni"]), lm.size()):
				fin.append(finale(b, lm[rng.randi_range(0, lm.size() - 1)]))
		campioni[b["id"]] = fin
	var migliore = {}
	var best = -INF
	for m in mie:
		var me = finale(a, m)
		var s = 0.0
		if nem.is_empty():
			s = 0.0
		else:
			for b in nem:
				var c: Array = campioni[b["id"]]
				var somma = 0.0
				var minimo = INF
				for lui in c:
					var v = valuta(a, me, b, lui)
					somma += v
					minimo = minf(minimo, v)
				var media = somma / maxf(1.0, c.size())
				# il nemico più vicino conta di più
				var peso = 1.0 / (1.0 + 0.25 * Hex.distanza(me["p"], R.pos(b)))
				s += (0.75 * media + 0.25 * minimo) * peso
		# bordi della mappa: poco spazio per manovrare
		var bordo = _vicinanza_bordo(me["p"])
		s -= maxf(0.0, 2.0 - bordo) * 3.0
		# fuga verso casa quando conviene
		if me["fuga"]:
			s += 40.0 if in_fuga else -30.0
		if in_fuga:
			var casa_r = R.riga_min - 1 if a["lato"] == "G" else R.riga_max + 1
			s -= absf(me["p"].y - casa_r) * 2.0
		# carburante e quota
		var carb_rest = int(a["carb"]) - int(m.get("carb", 0))
		if carb_rest < 10:
			s -= float(me["vel"]) * 0.8
		if me["quota"] == 0:
			s -= 6.0
		if int(m["quota"]) == -1 and int(a["quota"]) == 0:
			s += 20.0 if in_fuga and R.territorio_amico(a) else -50.0
		# acrobazie e manovre rischiose
		var g = Dati.geometria(m["codice"])
		if g["n"] == 1:
			s -= 4.0 + (3.0 if a["novellino"] else 0.0)
		if g["acrobatica"]:
			s -= 0.5
		s += rng.randf_range(-1.0, 1.0) * float(P["rumore"])
		if s > best:
			best = s
			migliore = m
	return migliore

func _in_nuvola_pos(x: Dictionary) -> bool:
	for nv in R.S.get("nuvole", []):
		if int(nv["quota"]) == int(x["quota"]):
			for c in nv["celle"]:
				if Vector2i(int(c[0]), int(c[1])) == x["p"]:
					return true
	return false

func _vicinanza_bordo(p: Vector2i) -> float:
	var d = 99.0
	for k in 6:
		var c = p
		for n in range(1, 4):
			c = Hex.vicino(c, k)
			if not R.celle.has(c):
				d = minf(d, float(n))
				break
	return d

## Sceglie i suoi attacchi: [{da, a, arma, raffica}]
func scegli_attacchi(a: Dictionary) -> Array:
	var out = []
	for arma in ["pilota", "osservatore"]:
		var migliore = {}
		var best = 0.0
		for b in R.nemici(a):
			var armi = R.puo_sparare(a, b)
			var ok = false
			for x in armi:
				if x["arma"] == arma:
					ok = true
			if not ok:
				continue
			for raff in R.raffiche_possibili(a, arma):
				var vf = R.valore_fuoco(a, b, arma, raff)
				var ev = danno_atteso(int(vf["valore"]))
				# le raffiche lunghe fanno inceppare: solo se ne vale la pena
				if raff == "lunga":
					ev -= 0.35 + (0.0 if _salute(b) > 0.35 else -0.6)
				if raff != "corta" and arma == "pilota":
					# obbligo di cambiare quota: evitalo se il bersaglio è a quota diversa e non serve
					if int(b["quota"]) != int(a["quota"]):
						ev -= 0.15
				ev *= 1.0 + (1.0 - _salute(b)) * 0.5
				if ev > best:
					best = ev
					migliore = {"da": a["id"], "a": b["id"], "arma": arma, "raffica": raff}
		if not migliore.is_empty():
			out.append(migliore)
	return out
