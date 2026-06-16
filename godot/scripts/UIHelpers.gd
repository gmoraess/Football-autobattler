class_name UIHelpers
## Constantes de paleta e helpers de UI reutilizados em todas as telas.
## Todos os métodos são static — não instanciar.

# ---- Paleta ----
const STONE    := Color("17110b")
const PANEL_A  := Color("241a10")
const PANEL_B  := Color("120c07")
const BRONZE   := Color("7a5a26")
const GOLD     := Color("d8b25a")
const GOLD2    := Color("f3da93")
const RUNE     := Color("e7d8b4")
const RUNE2    := Color("a8916a")
const HOME_KIT := Color("3f86ad")
const AWAY_KIT := Color("e07a3a")
const SEG_OFF  := Color("241a10")
const STA_COL  := Color("3aa86a")
const BAR_COL  := {"F":Color("e8842a"), "C":Color("2a8fd8"), "D":Color("d83a3a"), "E":Color("2eaa68")}
const BAR_TXT  := {"F":Color("ffba6a"), "C":Color("86d8ff"), "D":Color("ff8f8f"), "E":Color("9cffb6")}
const TYPE_COL := {"con":Color("3a78c9"), "fin":Color("c9803a"), "des":Color("c93a3a"), "def":Color("3ac96e")}

# ---- Widgets ----
static func sbf(bg: Color, border: Color, bw: int, radius: int, ph: int, pv: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = ph; s.content_margin_right = ph
	s.content_margin_top = pv;  s.content_margin_bottom = pv
	return s

static func lbl(txt: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l

static func clbl(txt: String, sz: int, col: Color) -> Label:
	var l := lbl(txt, sz, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func framed(bg: Color = PANEL_A, border: Color = BRONZE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sbf(bg, border, 2, 11, 10, 9))
	return p

static func gold_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color("1a1206"))
	b.add_theme_color_override("font_hover_color", Color("1a1206"))
	b.add_theme_color_override("font_pressed_color", Color("1a1206"))
	b.add_theme_stylebox_override("normal",  sbf(GOLD,              Color("8a6a2a"), 1, 9, 12, 11))
	b.add_theme_stylebox_override("hover",   sbf(GOLD2,             Color("8a6a2a"), 1, 9, 12, 11))
	b.add_theme_stylebox_override("pressed", sbf(Color("a87f2e"),   Color("8a6a2a"), 1, 9, 12, 11))
	b.add_theme_stylebox_override("disabled",sbf(Color("4a3a20"),   Color("3c2b12"), 1, 9, 12, 11))
	return b

static func icon_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(28, 28)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_stylebox_override("normal",  sbf(Color("140d07"), BRONZE, 1, 7, 4, 2))
	b.add_theme_stylebox_override("hover",   sbf(Color("1f1610"), GOLD,   1, 7, 4, 2))
	b.add_theme_stylebox_override("pressed", sbf(Color("140d07"), GOLD,   1, 7, 4, 2))
	return b

static func meter(frac: float, col: Color, txt: String, w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 15)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := ColorRect.new(); bg.color = Color("2a0f0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(bg)
	var fill := ColorRect.new(); fill.color = col
	fill.anchor_bottom = 1.0; fill.anchor_right = clampf(frac, 0.0, 1.0)
	c.add_child(fill)
	var l := clbl(txt, 9, Color.WHITE)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(l)
	return c

static func ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in n.get_children():
		ignore_mouse(ch)
