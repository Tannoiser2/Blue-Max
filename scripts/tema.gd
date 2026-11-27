class_name Tema
extends RefCounted
## Aspetto dell'interfaccia: carta invecchiata, inchiostro, rosso scuro. Font: IM Fell (titoli), Oswald (testi), Special Elite (documenti).

const CARTA := Color("e8dcc0")
const CARTA_SCURA := Color("d6c6a0")
const INCHIOSTRO := Color("2a2118")
const SEPPIA := Color("6b5437")
const ROSSO := Color("8e2420")
const ROSSO_CHIARO := Color("b8392f")
const BLU := Color("2e5f96")
const VERDE := Color("3f6b2f")
const ORO := Color("c9a23c")
const NOTTE := Color("1d1914")
const NOTTE_BORDO := Color("8c7350")
const TEDESCHI := Color("b8322a")
const ALLEATI := Color("2e6aa8")

static var _font := {}

static func font(n: String) -> Font:
	if _font.has(n):
		return _font[n]
	var f: Font
	match n:
		"titolo":
			f = load("res://assets/font/IMFellEnglishSC-Regular.ttf")
		"documento":
			f = load("res://assets/font/SpecialElite-Regular.ttf")
		"grassetto":
			var v = FontVariation.new()
			v.base_font = load("res://assets/font/Oswald.ttf")
			v.variation_opentype = {"wght": 600}
			f = v
		_:
			var v = FontVariation.new()
			v.base_font = load("res://assets/font/Oswald.ttf")
			v.variation_opentype = {"wght": 400}
			f = v
	_font[n] = f
	return f

static func colore_lato(l: String) -> Color:
	return TEDESCHI if l == "G" else ALLEATI

static func box(colore: Color, bordo: Color, larg := 2, raggio := 6, margine := 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = colore
	s.border_color = bordo
	s.set_border_width_all(larg)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = margine
	s.content_margin_right = margine
	s.content_margin_top = margine * 0.7
	s.content_margin_bottom = margine * 0.7
	return s

static func tema() -> Theme:
	var t = Theme.new()
	t.default_font = font("testo")
	t.default_font_size = 22
	t.set_color("font_color", "Label", INCHIOSTRO)
	t.set_stylebox("panel", "PanelContainer", box(CARTA, SEPPIA, 2, 8, 12))
	t.set_stylebox("panel", "Panel", box(CARTA, SEPPIA, 2, 8, 12))
	var b = box(ROSSO, Color("4a1210"), 2, 6, 12)
	var bh = box(ROSSO_CHIARO, Color("4a1210"), 2, 6, 12)
	var bp = box(Color("5e1714"), Color("2a0a09"), 2, 6, 12)
	var bd = box(Color("9b8f78"), Color("6f6553"), 2, 6, 12)
	var bf = box(ROSSO_CHIARO, ORO, 3, 6, 12)
	t.set_stylebox("normal", "Button", b)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("disabled", "Button", bd)
	t.set_stylebox("focus", "Button", bf)
	t.set_color("font_color", "Button", Color("f3ead6"))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color("f3ead6"))
	t.set_color("font_disabled_color", "Button", Color("e4dccb"))
	t.set_font("font", "Button", font("grassetto"))
	t.set_font_size("font_size", "Button", 22)
	for k in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		t.set_stylebox(k, "CheckBox", StyleBoxEmpty.new())
	t.set_color("font_color", "CheckBox", INCHIOSTRO)
	t.set_color("font_hover_pressed_color", "CheckBox", INCHIOSTRO)
	t.set_color("font_focus_color", "CheckBox", INCHIOSTRO)
	t.set_color("font_hover_color", "CheckBox", ROSSO)
	t.set_color("font_pressed_color", "CheckBox", INCHIOSTRO)
	t.set_color("font_color", "OptionButton", Color("f3ead6"))
	t.set_stylebox("normal", "OptionButton", box(SEPPIA, INCHIOSTRO, 2, 6, 10))
	t.set_stylebox("hover", "OptionButton", box(Color("7d6545"), INCHIOSTRO, 2, 6, 10))
	t.set_stylebox("pressed", "OptionButton", box(Color("4f3d28"), INCHIOSTRO, 2, 6, 10))
	t.set_stylebox("focus", "OptionButton", box(Color("7d6545"), ORO, 2, 6, 10))
	t.set_stylebox("panel", "PopupMenu", box(CARTA, SEPPIA, 2, 6, 8))
	t.set_color("font_color", "PopupMenu", INCHIOSTRO)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("hover", "PopupMenu", box(ROSSO, ROSSO, 0, 3, 4))
	t.set_font_size("font_size", "PopupMenu", 22)
	t.set_stylebox("normal", "LineEdit", box(Color("f6efde"), SEPPIA, 2, 5, 8))
	t.set_stylebox("focus", "LineEdit", box(Color("fffaf0"), ROSSO, 2, 5, 8))
	t.set_color("font_color", "LineEdit", INCHIOSTRO)
	t.set_color("default_color", "RichTextLabel", INCHIOSTRO)
	t.set_font("normal_font", "RichTextLabel", font("testo"))
	t.set_font("bold_font", "RichTextLabel", font("grassetto"))
	t.set_font_size("normal_font_size", "RichTextLabel", 21)
	t.set_font_size("bold_font_size", "RichTextLabel", 21)
	t.set_stylebox("panel", "TooltipPanel", box(Color("fbf4e2"), SEPPIA, 1, 4, 8))
	t.set_color("font_color", "TooltipLabel", INCHIOSTRO)
	t.set_stylebox("scroll", "VScrollBar", box(CARTA_SCURA, CARTA_SCURA, 0, 4, 2))
	t.set_stylebox("grabber", "VScrollBar", box(SEPPIA, SEPPIA, 0, 4, 2))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(ROSSO, ROSSO, 0, 4, 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(ROSSO, ROSSO, 0, 4, 2))
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 8)
	return t

## Etichetta che non si schiaccia: larghezza minima e a capo solo se serve
static func etichetta(testo: String, dim := 22, colore := INCHIOSTRO, tipo := "testo", larghezza := 0) -> Label:
	var l = Label.new()
	l.text = testo
	l.add_theme_font_override("font", font(tipo))
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", colore)
	if larghezza > 0:
		l.custom_minimum_size.x = larghezza
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func titolo(testo: String, dim := 40, colore := INCHIOSTRO) -> Label:
	return etichetta(testo, dim, colore, "titolo")

static func bottone(testo: String, cb: Callable, dim := 22, larghezza := 0) -> Button:
	var b = Button.new()
	b.text = testo
	b.add_theme_font_size_override("font_size", dim)
	b.custom_minimum_size = Vector2(maxi(larghezza, 60), maxi(44, dim + 22))
	b.pressed.connect(cb)
	b.focus_mode = Control.FOCUS_NONE
	return b

static func pannello(colore := CARTA, bordo := SEPPIA, margine := 14) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(colore, bordo, 2, 8, margine))
	return p

static func pannello_scuro(margine := 12) -> PanelContainer:
	var s = box(Color(NOTTE.r, NOTTE.g, NOTTE.b, 0.92), NOTTE_BORDO, 2, 8, margine)
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", s)
	return p


## Su iPad e telefoni il browser non apre la tastiera per i campi di Godot: al tocco si chiede il testo con la finestra del browser
static func tastiera(le: LineEdit, domanda: String) -> void:
	le.add_theme_font_size_override("font_size", 26)
	le.custom_minimum_size.y = 54
	if not OS.has_feature("web"):
		return
	le.gui_input.connect(func(ev: InputEvent):
		if not (ev is InputEventScreenTouch and not ev.pressed):
			return
		var js = "(function(){var r=window.prompt(%s,%s);return r===null?'__annulla__':r;})()" % [JSON.stringify(domanda), JSON.stringify(le.text)]
		var r = JavaScriptBridge.eval(js, true)
		if r == null or str(r) == "__annulla__":
			return
		var t = str(r)
		if le.max_length > 0:
			t = t.substr(0, le.max_length)
		le.text = t
		le.text_changed.emit(t)
		le.release_focus())
