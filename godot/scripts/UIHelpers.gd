## Constantes de paleta e helpers de UI reutilizados em todas as telas.
## (sem class_name — é sempre acessado via `const UIHelpers = preload(...)`)
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

## Botão ORNAMENTADO usando a textura button_gold.png (fallback p/ gold_btn).
## Botão ornamentado ROBUSTO: fundo = TextureRect filho (escala a textura inteira),
## texto = Label centralizado. Sem StyleBoxTexture (que estava bugando).
static func ornate_btn(txt: String, fsize: int = 16) -> Button:
	var b := Button.new()
	b.flat = true
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, empty)
	var t := frame_tex("button_gold")
	if t != null:
		var bg := TextureRect.new()
		bg.texture = t
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bg)
	else:
		b.add_theme_stylebox_override("normal", sbf(GOLD, Color("8a6a2a"), 1, 9, 12, 11))
	var lbl := Label.new()
	lbl.text = txt
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", Color("2a1606"))
	var tf := title_font()
	if tf != null: lbl.add_theme_font_override("font", tf)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(lbl)
	return b

## Tira escura full-width (topo/rodapé) com fio de ouro só na borda indicada.
static func strip(border_top: int, border_bottom: int) -> PanelContainer:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.03, 0.02, 0.66)
	s.border_color = BRONZE
	s.border_width_top = border_top
	s.border_width_bottom = border_bottom
	s.content_margin_left = 16; s.content_margin_right = 16
	s.content_margin_top = 8;   s.content_margin_bottom = 8
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", s)
	return p

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

# ==========================================================================
#  ASSETS (texturas com fallback) + FONTES
# ==========================================================================
const A_BG     := "res://assets/bg/"
const A_BEAST  := "res://assets/beasts/"
const A_CARD   := "res://assets/cards/"
const A_ICON   := "res://assets/icons/"
const A_RELIC  := "res://assets/icons/relics/"
const A_FRAME  := "res://assets/frames/"
const A_FONT   := "res://assets/fonts/"

## Carrega uma textura se existir (e estiver importada); senão devolve null.
static func tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var r: Resource = load(path)
		if r is Texture2D:
			return r
	return null

static func beast_tex(art: String) -> Texture2D:
	if art == "": return null
	return tex(A_BEAST + art + ".png")

static func card_tex(id: String) -> Texture2D:
	return tex(A_CARD + id + ".png")

static func icon_tex(name: String) -> Texture2D:
	return tex(A_ICON + name + ".png")

static func relic_tex(id: String) -> Texture2D:
	return tex(A_RELIC + id + ".png")

static func frame_tex(name: String) -> Texture2D:
	return tex(A_FRAME + name + ".png")

## StyleBox de textura 9-slice (fallback pro StyleBoxFlat se a textura faltar).
static func sbt(frame_name: String, margin: int, ph: int, pv: int,
		fb_bg: Color = PANEL_A, fb_border: Color = BRONZE) -> StyleBox:
	var t := frame_tex(frame_name)
	if t == null:
		return sbf(fb_bg, fb_border, 2, 11, ph, pv)
	var s := StyleBoxTexture.new()
	s.texture = t
	s.set_texture_margin_all(margin)
	s.content_margin_left = ph; s.content_margin_right = ph
	s.content_margin_top = pv;  s.content_margin_bottom = pv
	return s

## Painel com moldura de textura (panel.png) e fallback.
static func framed_t(ph: int = 10, pv: int = 9) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sbt("panel", 28, ph, pv))
	return p

## TextureRect que preenche mantendo proporção (pra arte de fera/fundo).
static func sprite(t: Texture2D, keep_aspect: bool = true) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

# ---- Fontes (carregadas uma vez) ----
static var _f_title: FontFile = null
static var _f_body: FontFile = null
static var _f_loaded := false

## Carrega o TTF direto (load_dynamic_font), driblando o sistema de importação.
## antialiasing OFF + subpixel OFF = renderização pixel-art crisp (combina com a arte).
static func _dyn_font(path: String, pixel: bool = true) -> FontFile:
	if not FileAccess.file_exists(path):
		return null
	var f := FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	if pixel:
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		f.hinting = TextServer.HINTING_NONE
		f.force_autohinter = false
	return f

static func _load_fonts() -> void:
	if _f_loaded: return
	_f_loaded = true
	# Fonte SUAVE (a arte é pixel, mas a fonte da referência é lisa):
	# Cinzel (serifada) pros títulos/placar/botão, Oswald (condensada) pros rótulos.
	_f_title = _dyn_font(A_FONT + "Cinzel.ttf", false)
	_f_body = _dyn_font(A_FONT + "Oswald.ttf", false)
	if _f_title == null: _f_title = _dyn_font(A_FONT + "PixelifySans.ttf")
	if _f_body == null: _f_body = _f_title

static func title_font() -> FontFile:
	_load_fonts(); return _f_title

static func body_font() -> FontFile:
	_load_fonts(); return _f_body

## Tema global: fonte condensada (Oswald) como padrão de toda a UI.
static func make_theme() -> Theme:
	var th := Theme.new()
	var b := body_font()
	if b != null:
		th.default_font = b
	return th

## Rótulo de título com fonte serifada (Cinzel) — usa fallback se faltar.
static func tlbl(txt: String, sz: int, col: Color) -> Label:
	var l := clbl(txt, sz, col)
	var f := title_font()
	if f != null:
		l.add_theme_font_override("font", f)
	return l
