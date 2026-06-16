extends Control
## HUD da partida + driver. Monta a UI por código (sem .tscn complexo) e
## conduz o MatchEngine. Tema "arena gótica" via StyleBoxFlat.

# ---- Paleta (mesma do HUD web) ----
const STONE := Color("17110b")
const PANEL_A := Color("241a10")
const PANEL_B := Color("120c07")
const BRONZE := Color("7a5a26")
const GOLD := Color("d8b25a")
const GOLD2 := Color("f3da93")
const RUNE := Color("e7d8b4")
const RUNE2 := Color("a8916a")
const HOME_KIT := Color("3f86ad")
const AWAY_KIT := Color("e07a3a")
const SEG_OFF := Color("241a10")
const STA_COL := Color("3aa86a")
const BAR_COL := {"F":Color("e8842a"), "C":Color("2a8fd8"), "D":Color("d83a3a"), "E":Color("2eaa68")}
const BAR_TXT := {"F":Color("ffba6a"), "C":Color("86d8ff"), "D":Color("ff8f8f"), "E":Color("9cffb6")}
const TYPE_COL := {"con":Color("3a78c9"), "fin":Color("c9803a"), "des":Color("c93a3a"), "def":Color("3ac96e")}

var engine: MatchEngine
var panel_root: MarginContainer

func _ready() -> void:
	randomize()
	# fundo de pedra
	var bg := ColorRect.new()
	bg.color = STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# container raiz com margens
	panel_root = MarginContainer.new()
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.add_theme_constant_override("margin_left", 10)
	panel_root.add_theme_constant_override("margin_right", 10)
	panel_root.add_theme_constant_override("margin_top", 10)
	panel_root.add_theme_constant_override("margin_bottom", 10)
	add_child(panel_root)
	_start_new()

func _start_new() -> void:
	var home := {"name":"Couraça", "crest":"🛡", "super":"casco"}
	var away := {"name":"Górtax", "crest":"🐂", "super":"bicuda"}
	var pdeck: Array = Cards.build(Cards.ATK_SPEC) + Cards.build(Cards.DEF_SPEC)
	var odeck: Array = Cards.build(Cards.ATK_SPEC) + Cards.build(Cards.DEF_SPEC)
	engine = MatchEngine.new()
	engine.begin(home, away, pdeck, odeck, 1.0)
	render()

# ==========================================================================
#  RENDER
# ==========================================================================
func render() -> void:
	for c in panel_root.get_children():
		c.free()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	panel_root.add_child(col)

	col.add_child(_top_bar())
	col.add_child(_scoreboard())
	col.add_child(_arena())
	col.add_child(_bottom())
	col.add_child(_log_box())

func _show_result() -> void:
	for c in panel_root.get_children():
		c.free()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	center.add_child(v)
	var win := engine.winner == "home"
	v.add_child(_center_label("🏆" if win else "💀", 60, GOLD2))
	v.add_child(_center_label("VITÓRIA!" if win else "Derrota", 30, GOLD2 if win else Color("ff6b6b")))
	var reasons := {"KO":"por NOCAUTE de fôlego!", "TIME":"no placar final.", "GOLDEN":"com GOL DE OURO!", "GOLEADA":"por GOLEADA!"}
	v.add_child(_center_label("%s venceu %s" % [engine._nm(engine.winner), reasons.get(engine.reason, "")], 14, RUNE2))
	v.add_child(_center_label("%d  x  %d" % [engine.score["home"], engine.score["away"]], 24, RUNE))
	var btn := _gold_button("↻  JOGAR DE NOVO")
	btn.pressed.connect(_start_new)
	v.add_child(btn)

# --- barra de topo: título + livro/engrenagem ---
func _top_bar() -> Control:
	var h := HBoxContainer.new()
	var title := _label("⚔ ARENA DOS MITOS", 13, GOLD2)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(title)
	h.add_child(_icon_button("📖", _on_book))
	h.add_child(_icon_button("⚙", _start_new))
	return h

# --- placar com fôlego + minimapa ---
func _scoreboard() -> Control:
	var panel := _framed()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	panel.add_child(h)
	h.add_child(_team_col("home"))
	# centro: placar + turno + minimapa
	var mid := VBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(_center_label("%d : %d" % [engine.score["home"], engine.score["away"]], 30, GOLD2))
	var trn := "TURNO %d / %d" % [mini(engine.turn, MatchEngine.TURNS), MatchEngine.TURNS]
	if engine.sudden_death: trn += " · MORTE SÚBITA"
	mid.add_child(_center_label(trn, 9, RUNE2))
	mid.add_child(_minimap())
	h.add_child(mid)
	h.add_child(_team_col("away"))
	return panel

func _team_col(side: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var kit: Color = HOME_KIT if side == "home" else AWAY_KIT
	var nm: String = engine._nm(side) + ("  (você)" if side == "home" else "")
	var name_lbl := _label(nm, 12, RUNE)
	name_lbl.add_theme_color_override("font_color", kit)
	v.add_child(name_lbl)
	# barra de fôlego
	var frac: float = float(engine.sta[side]) / float(engine.sta_max[side])
	v.add_child(_meter(frac, STA_COL, "%d/%d" % [engine.sta[side], engine.sta_max[side]], 170))
	if side == "away":
		v.alignment = BoxContainer.ALIGNMENT_END
	return v

func _minimap() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(132, 60)
	var field := ColorRect.new()
	field.color = Color("236e34")
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(field)
	# linha do meio
	var midline := ColorRect.new()
	midline.color = Color(1, 1, 1, 0.35)
	midline.position = Vector2(65, 3)
	midline.size = Vector2(1, 54)
	c.add_child(midline)
	var home_pos := [[18,30],[18,55],[30,42],[42,30],[42,55]]
	var away_pos := [[58,30],[58,55],[70,42],[82,30],[82,55]]
	for pos in home_pos: _dot(c, pos[0], pos[1], HOME_KIT)
	for pos in away_pos: _dot(c, pos[0], pos[1], AWAY_KIT)
	var bx: float = 34 if engine.possession == "home" else 62
	var ball := ColorRect.new()
	ball.color = Color.WHITE
	ball.size = Vector2(7, 7)
	ball.position = Vector2(bx / 100.0 * 132 - 3, 0.42 * 60 - 3)
	c.add_child(ball)
	return c

func _dot(parent: Control, xp: int, yp: int, col: Color) -> void:
	var r := ColorRect.new()
	r.color = col
	r.size = Vector2(8, 8)
	r.position = Vector2(float(xp) / 100.0 * 132 - 4, float(yp) / 100.0 * 60 - 4)
	parent.add_child(r)

# --- arena: barras esquerda | personagens | barras direita ---
func _arena() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(_bars_col("home"))
	h.add_child(_center_chars())
	h.add_child(_bars_col("away"))
	return h

func _bars_col(side: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	var has := engine.possession == side
	var b: Dictionary = engine.bars[side]
	var bm: Dictionary = engine.bar_max[side]
	v.add_child(_bar(side, "F", "🎯 FINALIZAÇÃO", "Encher para chutar ao gol", b["F"], bm["F"], has))
	v.add_child(_bar(side, "C", "⚽ CONTROLE", "Mantém a posse da bola", b["C"], MatchEngine.CD_CAP, has))
	v.add_child(_bar(side, "D", "🦵 DESARME", "Rouba a bola do oponente", b["D"], MatchEngine.CD_CAP, not has))
	v.add_child(_bar(side, "E", "🛡 DEFESA", "Bloqueia o chute (guard.: %d)" % engine.saves[side], b["E"], bm["E"], not has))
	return v

func _bar(side: String, key: String, name: String, desc: String, cur: int, mx: int, active: bool) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _sbf(PANEL_B, GOLD if active else Color("3c2b12"), 1, 9, 8, 6))
	if not active:
		box.modulate = Color(1, 1, 1, 0.45)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	box.add_child(v)
	# cabeçalho
	var hd := HBoxContainer.new()
	var nl := _label(name, 9, BAR_TXT[key])
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(nl)
	hd.add_child(_label("%d/%d" % [cur, mx], 9, RUNE2))
	v.add_child(hd)
	# segmentos
	var segs := HBoxContainer.new()
	segs.add_theme_constant_override("separation", 2)
	var fill := int(round(clampf(float(cur) / float(maxi(1, mx)), 0.0, 1.0) * 14.0))
	for i in 14:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(0, 9)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.color = BAR_COL[key] if i < fill else SEG_OFF
		segs.add_child(r)
	v.add_child(segs)
	# descrição
	var dl := _label(desc, 8, RUNE2)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(dl)
	return box

func _center_chars() -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.custom_minimum_size = Vector2(108, 0)
	v.add_theme_constant_override("separation", 16)
	# jogador (home)
	var hc := VBoxContainer.new()
	hc.alignment = BoxContainer.ALIGNMENT_CENTER
	if engine.possession == "home":
		hc.add_child(_banner("⚽ POSSE DE BOLA"))
	hc.add_child(_beast(engine.home, HOME_KIT))
	if engine.possession == "home":
		hc.add_child(_center_label("⚽", 16, Color.WHITE))
	v.add_child(hc)
	# inimigo (away)
	var ac := VBoxContainer.new()
	ac.alignment = BoxContainer.ALIGNMENT_CENTER
	if engine.enemy_plan.get("icon", "") != "":
		ac.add_child(_intent(engine.enemy_plan["icon"]))
	ac.add_child(_beast(engine.away, AWAY_KIT))
	if engine.possession == "away":
		ac.add_child(_center_label("⚽", 16, Color.WHITE))
	v.add_child(ac)
	return v

func _beast(beast: Dictionary, kit: Color) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(74, 86)
	var sb := _sbf(kit, BRONZE, 2, 9, 0, 0)
	sb.corner_radius_top_left = 36
	sb.corner_radius_top_right = 36
	p.add_theme_stylebox_override("panel", sb)
	var cc := CenterContainer.new()
	p.add_child(cc)
	cc.add_child(_center_label(beast.get("crest", "?"), 38, Color.WHITE))
	return p

func _banner(txt: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sbf(GOLD, Color("8a6a2a"), 1, 4, 8, 3))
	var l := _center_label(txt, 9, Color("1a1206"))
	p.add_child(l)
	return p

func _intent(icon: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sbf(Color("160d05"), GOLD, 2, 16, 5, 5))
	p.add_child(_center_label(icon, 18, GOLD2))
	return p

# --- faixa inferior: energia + mão + ações ---
func _bottom() -> Control:
	var panel := _framed()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)
	# energia
	var ebox := PanelContainer.new()
	ebox.custom_minimum_size = Vector2(62, 0)
	ebox.add_theme_stylebox_override("panel", _sbf(Color("12203f"), BRONZE, 1, 10, 6, 6))
	var ev := VBoxContainer.new()
	ev.alignment = BoxContainer.ALIGNMENT_CENTER
	ebox.add_child(ev)
	ev.add_child(_center_label("%d/%d" % [engine.energy, engine.energy_max], 22, Color("dff1ff")))
	ev.add_child(_center_label("ENERGIA", 8, Color("a9cdea")))
	h.add_child(ebox)
	# mão (rolagem horizontal)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 120)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hand_h := HBoxContainer.new()
	hand_h.add_theme_constant_override("separation", 6)
	scroll.add_child(hand_h)
	for i in engine.hand.size():
		hand_h.add_child(_card(i))
	h.add_child(scroll)
	# ações
	var av := VBoxContainer.new()
	av.custom_minimum_size = Vector2(112, 0)
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	av.add_theme_constant_override("separation", 6)
	if engine.super_name != "":
		var ready := engine.fury >= 100
		var sbtn := Button.new()
		sbtn.text = "⚡ SUPER %d%%" % engine.fury
		sbtn.add_theme_font_size_override("font_size", 12)
		var armed := engine.super_armed != ""
		var scol: Color = GOLD if armed else (Color("9a5bff") if ready else Color("2a1f3e"))
		sbtn.add_theme_stylebox_override("normal", _sbf(scol, GOLD if ready else Color("7a3df5"), 1, 9, 8, 8))
		sbtn.add_theme_stylebox_override("hover", _sbf(scol.lightened(0.1), GOLD, 1, 9, 8, 8))
		sbtn.add_theme_stylebox_override("pressed", _sbf(scol, GOLD, 1, 9, 8, 8))
		sbtn.pressed.connect(_on_super)
		av.add_child(sbtn)
	var endb := _gold_button("▶ FIM DE TURNO")
	endb.pressed.connect(_on_end_turn)
	av.add_child(endb)
	h.add_child(av)
	return panel

func _card(idx: int) -> Control:
	var id: String = engine.hand[idx]
	var c: Dictionary = Cards.ALL[id]
	var can: bool = c["cost"] <= engine.energy and not engine.busy
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(84, 110)
	btn.disabled = not can
	var border: Color = TYPE_COL.get(c["type"], BRONZE)
	btn.add_theme_stylebox_override("normal", _sbf(Color("1d1409"), border, 2, 9, 4, 4))
	btn.add_theme_stylebox_override("hover", _sbf(Color("261b0e"), GOLD, 2, 9, 4, 4))
	btn.add_theme_stylebox_override("pressed", _sbf(Color("1d1409"), GOLD, 2, 9, 4, 4))
	btn.add_theme_stylebox_override("disabled", _sbf(Color("140e07"), Color("3c2b12"), 2, 9, 4, 4))
	btn.pressed.connect(_on_card.bind(idx))
	# conteúdo (ignora o mouse para o clique chegar ao botão)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	v.add_child(_center_label("⚡%d" % c["cost"], 11, GOLD2))
	v.add_child(_center_label(c.get("ic", ""), 22, Color.WHITE))
	v.add_child(_center_label(c["nm"], 9, RUNE))
	var ds := _center_label(c.get("ds", ""), 8, RUNE2)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ds)
	btn.add_child(v)
	_ignore_mouse(v)  # garante que o clique chegue ao botão
	return btn

func _ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in n.get_children():
		_ignore_mouse(ch)

func _log_box() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sbf(Color("0c0805"), Color("3c2b12"), 1, 8, 8, 6))
	var v := VBoxContainer.new()
	p.add_child(v)
	var lines: Array = engine.logs.slice(maxi(0, engine.logs.size() - 3))
	if lines.is_empty():
		lines = ["Encha as barras com cartas. Posse: foque Finalização + Controle."]
	for line in lines:
		v.add_child(_label(line, 10, RUNE2))
	return p

# ==========================================================================
#  AÇÕES
# ==========================================================================
func _on_card(idx: int) -> void:
	if engine.busy: return
	if engine.play_card(idx):
		render()

func _on_super() -> void:
	if engine.busy: return
	engine.arm_super()
	render()

func _on_book() -> void:
	# feedback simples (sem tela de baralho ainda)
	print("Mão %d · Baralho %d · Descarte %d" % [engine.hand.size(), engine.deck.size(), engine.discard.size()])

func _on_end_turn() -> void:
	if engine.over or engine.busy: return
	engine.busy = true
	engine.end_turn()
	render()  # mostra a resolução (roubo/gol/defesa)
	await get_tree().create_timer(0.8).timeout
	engine.busy = false
	if engine.over:
		_show_result()
	else:
		engine.start_turn()
		render()

# ==========================================================================
#  HELPERS de UI
# ==========================================================================
func _sbf(bg: Color, border: Color, bw: int, radius: int, ph: int, pv: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = ph
	s.content_margin_right = ph
	s.content_margin_top = pv
	s.content_margin_bottom = pv
	return s

func _framed() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sbf(PANEL_A, BRONZE, 2, 11, 10, 9))
	return p

func _label(txt: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _center_label(txt: String, size: int, col: Color) -> Label:
	var l := _label(txt, size, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _meter(frac: float, col: Color, txt: String, width: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 15)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := ColorRect.new()
	bg.color = Color("2a0f0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(bg)
	var fill := ColorRect.new()
	fill.color = col
	fill.anchor_bottom = 1.0
	fill.anchor_right = clampf(frac, 0.0, 1.0)
	c.add_child(fill)
	var l := _center_label(txt, 9, Color.WHITE)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(l)
	return c

func _icon_button(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(28, 28)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_stylebox_override("normal", _sbf(Color("140d07"), BRONZE, 1, 7, 4, 2))
	b.add_theme_stylebox_override("hover", _sbf(Color("1f1610"), GOLD, 1, 7, 4, 2))
	b.add_theme_stylebox_override("pressed", _sbf(Color("140d07"), GOLD, 1, 7, 4, 2))
	b.pressed.connect(cb)
	return b

func _gold_button(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color("1a1206"))
	b.add_theme_color_override("font_hover_color", Color("1a1206"))
	b.add_theme_color_override("font_pressed_color", Color("1a1206"))
	b.add_theme_stylebox_override("normal", _sbf(GOLD, Color("8a6a2a"), 1, 9, 12, 11))
	b.add_theme_stylebox_override("hover", _sbf(GOLD2, Color("8a6a2a"), 1, 9, 12, 11))
	b.add_theme_stylebox_override("pressed", _sbf(Color("a87f2e"), Color("8a6a2a"), 1, 9, 12, 11))
	return b
