extends Node
## Dati del gioco (autoload "Dati"): aerei, manovre, pedine-danno, tabelle, mappa, scenari, assi.

var aerei = {}          # id -> Dictionary
var ordine_aerei = []   # id nell'ordine della tabella
var manovre = {}        # "12" -> {passi, prua, nome, acrobatica, non_ripetibile}
var danni = {}          # rosse, blu, testi
var comb = {}           # tabelle di combattimento
var mappa = {}

const QUOTE := ["Molto Bassa", "Bassa", "Media", "Alta", "Molto Alta"]
const QUOTE_BREVI := ["BB", "B", "M", "A", "MA"]
const NAZIONI := {
	"germania": {"nome": "Germania", "lato": "G", "agg": "tedesco"},
	"inghilterra": {"nome": "Inghilterra", "lato": "A", "agg": "inglese"},
	"francia": {"nome": "Francia", "lato": "A", "agg": "francese"},
	"usa": {"nome": "Stati Uniti", "lato": "A", "agg": "americano"},
}
const ABILITA := {
	"evasive": {"nome": "Manovre Evasive", "testo": "Non può essere tallonato da un nemico che non sia un Asso."},
	"acrobatiche": {"nome": "Manovre Acrobatiche", "testo": "Esegue tutte le manovre come se non fossero acrobatiche."},
	"tallonare": {"nome": "Tallonare", "testo": "Può tallonare da 4 esagoni invece che da 3."},
	"stabilita": {"nome": "Stabilità", "testo": "La stabilità dell'aereo migliora di un grado (C diventa B, B diventa A)."},
	"bonus_tiro": {"nome": "Bonus al Tiro", "testo": "Aggiunge 1 al tiro di dado (un 6 resta 6)."},
	"inceppamenti": {"nome": "Inceppamenti", "testo": "Le mitragliatrici si inceppano solo con un 6 e si disinceppano con 3-6."},
	"angolato": {"nome": "Tiro Angolato", "testo": "Ignora la penalità del tiro angolato."},
	"mira": {"nome": "Mira", "testo": "Solo per un Asso: +1 al valore di fuoco."},
	"portata": {"nome": "Portata Estesa", "testo": "Solo per un Asso: a 3 esagoni spara come da 2, a 2 come da 1."},
}

func _ready() -> void:
	carica()

func _json(p: String) -> Variant:
	var f = FileAccess.open(p, FileAccess.READ)
	if f == null:
		push_error("manca " + p)
		return {}
	return JSON.parse_string(f.get_as_text())

func carica() -> void:
	if not aerei.is_empty():
		return
	var a = _json("res://data/aerei.json")
	for x in a["aerei"]:
		aerei[x["id"]] = x
		ordine_aerei.append(x["id"])
	manovre = _json("res://data/manovre.json")["manovre"]
	danni = _json("res://data/danni.json")
	comb = _json("res://data/combattimento.json")
	mappa = _json("res://data/mappa.json")

## "12S2" -> {n: 12, dir: "S", vel: 2}
static func codice(c: String) -> Dictionary:
	var n = ""
	var i = 0
	while i < c.length() and c[i].is_valid_int():
		n += c[i]
		i += 1
	var d = c[i] if i < c.length() else "A"
	var v = c.substr(i + 1)
	return {"n": int(n), "dir": d, "vel": int(v) if v != "" else 0}

func geometria(c: String) -> Dictionary:
	var k = codice(c)
	var m: Dictionary = manovre[str(k["n"])]
	var passi: Array = m["passi"].duplicate()
	var prua: int = m["prua"]
	if k["dir"] == "D":
		for i in passi.size():
			passi[i] = -passi[i] if absi(passi[i]) != 3 else 3
		prua = -prua if absi(prua) != 3 else 3
	if k["dir"] == "S" and k["n"] == 1:
		prua = -1
	if k["dir"] == "A" and k["n"] == 1:
		prua = 0
	return {"passi": passi, "prua": prua, "n": k["n"], "dir": k["dir"], "vel": k["vel"],
		"acrobatica": m["acrobatica"], "non_ripetibile": m["non_ripetibile"], "nome": m["nome"]}

func nome_manovra(c: String) -> String:
	if c == "0A2":
		return "Avvitamento"
	var g = geometria(c)
	var lato = {"S": " a sinistra", "D": " a destra", "A": ""}[g["dir"]]
	var base: String = g["nome"]
	if g["n"] in [6, 7, 12, 13, 18, 19, 25, 26, 32, 33, 35, 34]:
		lato = ""
	return base + lato

func testo_pedina(p: Dictionary) -> String:
	var righe = []
	if p.has("spec"):
		var t: String = danni["testi"][p["spec"]]
		match p["spec"]:
			"timone":
				t += ": solo manovre a %s per %d turni" % ["Destra" if p["dir"] == "D" else "Sinistra", p["turni"]]
			"serbatoio":
				t += ": perdi %d punti carburante" % p["carb"]
			"oss_ferito":
				t += ": non può sparare per 3 turni"
			"ferito_avanti":
				t += ": manovra Avanti il prossimo turno"
			"ferito_lento":
				t += ": manovra più lenta il prossimo turno"
			"ala_lacerata_veloce", "motore_colpito":
				t += ": niente velocità 3 o 4"
			"ala_lacerata", "montante":
				t += ": nessuna manovra speciale"
		righe.append(t)
	for k in ["ala", "fusoliera", "coda", "motore"]:
		if p.has(k):
			righe.append("%d %s" % [p[k], k])
	return "\n".join(righe)
