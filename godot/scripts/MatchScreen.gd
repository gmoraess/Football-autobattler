extends Control
## HUD da partida (paisagem) + driver do MatchEngine. Arte pintada + animações (Parte 1).
const UIHelpers = preload("res://scripts/UIHelpers.gd")
const Cards = preload("res://scripts/Cards.gd")
const MatchEngine = preload("res://scripts/MatchEngine.gd")

signal match_ended(won: bool)

const STAT_ICON := {"F": "stat_fin", "C": "stat_con", "D": "stat_des", "E": "stat_def"}

var engine: MatchEngine
var layer: Control          # tudo menos o fundo (pra re-render)

# --- estado p/ animação (valores anteriores) ---
var _prev_bars := {"home": {"F": 0.0, "C": 0.0, "D": 0.0, "E": 0.0},
				   "away": {"F": 0.0, "C": 0.0, "D": 0.0, "E": 0.0}}
var _prev_energy := 0
var _prev_score := {"home": 0, "away": 0}
var _fresh_hand := true      # anima a entrada da mão (compra) neste render
var _beast_node := {"home": null, "away": null}   # refs visuais das feras (reações)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var arena := UIHelpers.tex(UIHelpers.A_BG + "arena.png")
	if arena != null:
		var bg := TextureRect.new()
		bg.texture = arena
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.40)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
	else:
		var bg := ColorRect.new()
		bg.color = UIHelpers.STONE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	# faixas pintadas (topo/rodapé) — fundo da HUD, atrás do conteúdo
	_strip_bg("topbar_bg", true)
	_strip_bg("bottombar_bg", false)
	layer = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	_start_match()

## Coloca uma faixa pintada full-width no topo ou no rodapé (band no topo da imagem).
func _strip_bg(tex_name: String, is_top: bool) -> void:
	var t := UIHelpers.frame_tex(tex_name)
	if t == null: return
	var W := 1280.0
	var h := W * float(t.get_height()) / float(t.get_width())
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tr.offset_left = 0; tr.offset_right = 0
	if is_top:
		tr.offset_top = -8
		tr.offset_bottom = h - 8
	else:
		# a "band" pintada fica no topo da imagem (~23% da altura); encosta no rodapé (720)
		var band := h * 0.23
		tr.offset_top = 720.0 - band - 2.0
		tr.offset_bottom = tr.offset_top + h
	add_child(tr)

func _start_match() -> void:
	var node: Dictionary = GameState.current_node
	var home: Dictionary = {
		"name": GameState.beast.get("name", "Fera"),
		"crest": GameState.beast.get("crest", "🛡"),
		"art": GameState.beast.get("art", ""),
	}
	var enemy: Dictionary = node.get("enemy", {})
	if enemy.is_empty():
		enemy = {"name": "Oponente", "crest": "?", "art": ""}
	var away: Dictionary = {
		"name": enemy.get("name", "Oponente"),
		"crest": enemy.get("crest", "?"),
		"art": enemy.get("art", ""),
	}
	var pdeck: Array = GameState.deck.duplicate()
	var odeck: Array = GameState.enemy_deck(node.get("deck_key", "normal"))
	var diff: float = node.get("diff", 1.0)
	var mods: Dictionary = GameState.get_match_mods()
	engine = MatchEngine.new()
	engine.begin(home, away, pdeck, odeck, diff, mods)
	_sync_prev()
	_fresh_hand = true
	render()

func _sync_prev() -> void:
	for side in ["home", "away"]:
		for k in ["F", "C", "D", "E"]:
			_prev_bars[side][k] = _frac(side, k)
	_prev_energy = engine.energy
	_prev_score = {"home": engine.score["home"], "away": engine.score["away"]}

func _frac(side: String, key: String) -> float:
	var cur: int = engine.bars[side][key]
	var mx: int
	match key:
		"F": mx = engine.bar_max[side]["F"]
		"E": mx = engine.bar_max[side]["E"]
		_:  mx = MatchEngine.CD_CAP
	return clampf(float(cur) / float(maxi(1, mx)), 0.0, 1.0)

# ==========================================================================
#  RENDER
# ==========================================================================
func render() -> void:
	for c in layer.get_children():
		layer.remove_child(c)
		c.queue_free()
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		root.add_theme_constant_override(side, 8)
	layer.add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	root.add_child(col)

	col.add_child(_scoreboard())
	col.add_child(_field_strip())
	var mid := _arena_row()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mid)
	col.add_child(_bottom())

	_sync_prev()        # depois de montar, o "anterior" passa a ser o estado atual
	_fresh_hand = false

# --- placar superior ---
func _scoreboard() -> Control:
	# transparente: o chrome vem do topbar_bg pintado. Margens laterais limpam
	# os crests embutidos; o conteúdo encaixa nos vãos.
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 145)
	mc.add_theme_constant_override("margin_right", 145)
	mc.add_theme_constant_override("margin_top", 14)
	mc.add_theme_constant_override("margin_bottom", 4)
	mc.custom_minimum_size = Vector2(0, 150)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	mc.add_child(h)
	h.add_child(_team_head("home"))
	h.add_child(_score_plate())
	h.add_child(_team_head("away"))
	return mc

func _score_plate() -> Control:
	var c := Control.new()
	# proporção ~ da score_plate (1967x799 ≈ 2.46) pra ela preencher sem sobrar borda
	c.custom_minimum_size = Vector2(238, 98)
	var plate := UIHelpers.frame_tex("score_plate")
	if plate != null:
		var tr := TextureRect.new(); tr.texture = plate
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(tr)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var score_lbl := UIHelpers.tlbl("%d : %d" % [engine.score["home"], engine.score["away"]], 40, Color("f4eee2"))
	v.add_child(score_lbl)
	if engine.score["home"] != _prev_score["home"] or engine.score["away"] != _prev_score["away"]:
		_pop(score_lbl, 1.4)
	var trn := "TURNO %d / %d" % [mini(engine.turn, MatchEngine.TURNS), MatchEngine.TURNS]
	if engine.sudden_death: trn += " · MS"
	v.add_child(UIHelpers.clbl(trn, 9, UIHelpers.GOLD))
	c.add_child(v)
	return c

func _crest_rect() -> Control:
	var crest := UIHelpers.frame_tex("banner_crest")
	if crest == null:
		return null
	var cr := TextureRect.new()
	cr.texture = crest
	cr.custom_minimum_size = Vector2(112, 66)
	cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return cr

func _team_head(side: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	var nl := UIHelpers.tlbl(engine._nm(side), 20, Color("f3ece0"))
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side == "home" else HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(nl)
	v.add_child(_sta_bar(side))
	return v

## Atlas que recorta só a "band" da bar_frame (tira a margem transparente vertical).
func _bar_frame_atlas() -> Texture2D:
	var t := UIHelpers.frame_tex("bar_frame")
	if t == null: return null
	var at := AtlasTexture.new()
	at.atlas = t
	at.region = Rect2(0, 330, 1536, 364)
	return at

## Barra de fôlego: preenchimento teal/vermelho dentro da moldura pintada bar_frame.
func _sta_bar(side: String) -> Control:
	var col: Color = Color("3ec3c3") if side == "home" else Color("d8463a")
	var frac: float = float(engine.sta[side]) / float(engine.sta_max[side])
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	var top := HBoxContainer.new()
	var lab := UIHelpers.lbl("FÔLEGO", 9, col)
	var num := UIHelpers.lbl("%d/%d" % [engine.sta[side], engine.sta_max[side]], 9, UIHelpers.RUNE)
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if side == "home":
		top.add_child(lab); top.add_child(sp); top.add_child(num)
	else:
		top.add_child(num); top.add_child(sp); top.add_child(lab)
	v.add_child(top)
	var c := Control.new()
	c.custom_minimum_size = Vector2(230, 52)
	var fr := _bar_frame_atlas()
	if fr != null:
		# preenchimento dentro do "buraco" da moldura (frações estimadas)
		var fill := ColorRect.new(); fill.color = col
		fill.anchor_top = 0.34; fill.anchor_bottom = 0.66
		if side == "home":
			fill.anchor_left = 0.11; fill.anchor_right = 0.11 + 0.78 * frac
		else:
			fill.anchor_left = 0.89 - 0.78 * frac; fill.anchor_right = 0.89
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(fill)
		var tr := TextureRect.new(); tr.texture = fr
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(tr)
	else:
		# fallback sem moldura
		var bg := ColorRect.new(); bg.color = Color("1a0c0c")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); c.add_child(bg)
		var fill := ColorRect.new(); fill.color = col
		fill.anchor_top = 0.3; fill.anchor_bottom = 0.7
		fill.anchor_left = 0.0; fill.anchor_right = frac
		c.add_child(fill)
	v.add_child(c)
	return v

const MM_W := 330.0
const MM_H := 118.0

## Faixa centralizada com o campo (entre o placar e a arena).
func _field_strip() -> Control:
	var cc := CenterContainer.new()
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("0c1a0c"), UIHelpers.BRONZE, 2, 8, 5, 5))
	box.add_child(_minimap())
	cc.add_child(box)
	return cc

func _minimap() -> Control:
	var W := MM_W
	var H := MM_H
	var c := Control.new()
	c.custom_minimum_size = Vector2(W, H)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var field := ColorRect.new(); field.color = Color("2f8a3c")
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(field)
	# listras de grama
	for i in 8:
		if i % 2 == 0:
			_rect(c, Vector2(i * W / 8.0, 0), Vector2(W / 8.0, H), Color(1, 1, 1, 0.05))
	var line := Color(1, 1, 1, 0.6)
	# linha central + círculo
	_rect(c, Vector2(W / 2 - 1, 5), Vector2(2, H - 10), line)
	_circle_outline(c, Vector2(W / 2, H / 2), 28, line)
	_rect(c, Vector2(W / 2 - 2, H / 2 - 2), Vector2(4, 4), line)  # ponto central
	# grande área + pequena área (os dois lados)
	_outline(c, Vector2(2, H / 2 - 36), Vector2(44, 72), line)
	_outline(c, Vector2(W - 46, H / 2 - 36), Vector2(44, 72), line)
	_outline(c, Vector2(2, H / 2 - 18), Vector2(20, 36), line)
	_outline(c, Vector2(W - 22, H / 2 - 18), Vector2(20, 36), line)
	# gols
	_rect(c, Vector2(0, H / 2 - 10), Vector2(3, 20), Color(1, 1, 1, 0.9))
	_rect(c, Vector2(W - 3, H / 2 - 10), Vector2(3, 20), Color(1, 1, 1, 0.9))
	# GK
	var gk1 := UIHelpers.lbl("GK", 9, Color(1, 1, 1, 0.85)); gk1.position = Vector2(10, H / 2 - 42); c.add_child(gk1)
	var gk2 := UIHelpers.lbl("GK", 9, Color(1, 1, 1, 0.85)); gk2.position = Vector2(W - 30, H / 2 - 42); c.add_child(gk2)
	# formações (4-1) por lado
	var hp := [[26, H / 2], [78, H / 2 - 32], [78, H / 2 + 32], [126, H / 2], [164, H / 2 - 24]]
	var ap := [[W - 26, H / 2], [W - 78, H / 2 - 32], [W - 78, H / 2 + 32], [W - 126, H / 2], [W - 164, H / 2 + 24]]
	for p in hp: _bdot(c, p[0], p[1], UIHelpers.HOME_KIT)
	for p in ap: _bdot(c, p[0], p[1], UIHelpers.AWAY_KIT)
	# bola
	var bx: float = W * 0.42 if engine.possession == "home" else W * 0.58
	var ball_tex := UIHelpers.icon_tex("ball")
	if ball_tex != null:
		var bt := TextureRect.new(); bt.texture = ball_tex
		bt.size = Vector2(15, 15); bt.position = Vector2(bx - 7, H * 0.5 - 7)
		bt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(bt)
	else:
		var ball := ColorRect.new(); ball.color = Color.WHITE
		ball.size = Vector2(9, 9); ball.position = Vector2(bx - 4, H * 0.5 - 4)
		ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(ball)
	return c

func _circle_outline(parent: Control, center: Vector2, r: float, col: Color) -> void:
	var p := Panel.new()
	p.position = center - Vector2(r, r); p.size = Vector2(r * 2, r * 2)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = col; sb.set_border_width_all(1); sb.set_corner_radius_all(int(r))
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)

func _bdot(parent: Control, x: float, y: float, col: Color) -> void:
	var p := Panel.new()
	p.position = Vector2(x - 6, y - 6); p.size = Vector2(12, 12)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new(); sb.bg_color = col
	sb.border_color = Color(0, 0, 0, 0.5); sb.set_border_width_all(1); sb.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)

func _rect(parent: Control, pos: Vector2, size: Vector2, col: Color) -> void:
	var r := ColorRect.new(); r.color = col; r.position = pos; r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

func _outline(parent: Control, pos: Vector2, size: Vector2, col: Color) -> void:
	var p := Panel.new(); p.position = pos; p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = col; sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)

func _dot(parent: Control, xp: int, yp: int, col: Color) -> void:
	var r := ColorRect.new(); r.color = col; r.size = Vector2(8, 8)
	r.position = Vector2(float(xp) - 4, float(yp) - 4)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

# --- linha central: barras | feras | barras ---
func _arena_row() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(_bars_col("home"))
	h.add_child(_beasts_center())
	h.add_child(_bars_col("away"))
	return h

func _bars_col(side: String) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(248, 0)
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	var has := engine.possession == side
	v.add_child(_bar(side, "F", "FINALIZAÇÃO", "Encher → chuta ao gol", has))
	v.add_child(_bar(side, "C", "CONTROLE DE BOLA", "Mantém a posse", has))
	v.add_child(_bar(side, "D", "DESARME", "Rouba a bola do oponente", not has))
	v.add_child(_bar(side, "E", "DEFESA", "Bloqueia (guardadas: %d)" % engine.saves[side], not has))
	return v

func _bar(side: String, key: String, name: String, desc: String, active: bool) -> Control:
	var cur: int = engine.bars[side][key]
	var mx: int = engine.bar_max[side]["F"] if key == "F" else (engine.bar_max[side]["E"] if key == "E" else MatchEngine.CD_CAP)
	var frac: float = clampf(float(cur) / float(maxi(1, mx)), 0.0, 1.0)
	var prev: float = _prev_bars[side][key]

	var mirror := side == "away"
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel",
		UIHelpers.sbf(Color(0.05, 0.035, 0.02, 0.5), UIHelpers.GOLD if active else Color(0.42, 0.31, 0.14, 0.45), 1, 8, 9, 6))
	if not active: box.modulate = Color(1, 1, 1, 0.62)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 3); box.add_child(v)
	var hd := HBoxContainer.new(); hd.add_theme_constant_override("separation", 7)
	var icon_sq := _stat_icon_box(key)
	var nl := UIHelpers.lbl(name, 13, UIHelpers.BAR_TXT[key])
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if mirror else HORIZONTAL_ALIGNMENT_LEFT
	var val := UIHelpers.lbl("%d/%d" % [cur, mx], 10, UIHelpers.RUNE2)
	if mirror:
		hd.add_child(val); hd.add_child(nl)
		if icon_sq != null: hd.add_child(icon_sq)
	else:
		if icon_sq != null: hd.add_child(icon_sq)
		hd.add_child(nl); hd.add_child(val)
	v.add_child(hd)

	# barra contínua (tween) + barra-fantasma + divisórias por cima
	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 10)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := ColorRect.new(); bg.color = UIHelpers.SEG_OFF
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.add_child(bg)
	# fantasma (só quando caiu): mostra o nível anterior recuando
	if prev > frac + 0.001:
		var ghost := ColorRect.new(); ghost.color = Color(1, 1, 1, 0.25)
		ghost.anchor_top = 0.0; ghost.anchor_bottom = 1.0
		ghost.anchor_left = 0.0; ghost.anchor_right = prev
		track.add_child(ghost)
		_tween_prop(ghost, "anchor_right", frac, 0.45, 0.15)
	var fill := ColorRect.new(); fill.color = UIHelpers.BAR_COL[key]
	fill.anchor_top = 0.0; fill.anchor_bottom = 1.0
	fill.anchor_left = 0.0; fill.anchor_right = prev
	track.add_child(fill)
	_tween_prop(fill, "anchor_right", frac, 0.3, 0.0)
	if frac >= 0.999 and prev < 0.999:
		_flash(fill)
	# divisórias (look segmentado, por cima)
	for i in range(1, 14):
		var d := ColorRect.new(); d.color = Color(0, 0, 0, 0.55)
		d.anchor_left = float(i) / 14.0; d.anchor_right = float(i) / 14.0
		d.anchor_top = 0.0; d.anchor_bottom = 1.0
		d.offset_right = 1
		track.add_child(d)
	v.add_child(track)

	var dl := UIHelpers.lbl(desc, 8, UIHelpers.RUNE2)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if mirror else HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(dl)
	return box

## Ícone de status num quadradinho com moldura (estilo da referência).
func _stat_icon_box(key: String) -> Control:
	var ic := UIHelpers.icon_tex(STAT_ICON[key])
	if ic == null:
		return null
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("140d07"), UIHelpers.BRONZE, 1, 5, 3, 3))
	var ir := TextureRect.new(); ir.texture = ic
	ir.custom_minimum_size = Vector2(20, 20)
	ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(ir)
	return box

func _beasts_center() -> Control:
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(_beast_slot("home", engine.home, UIHelpers.HOME_KIT, engine.possession == "home", ""))
	h.add_child(_beast_slot("away", engine.away, UIHelpers.AWAY_KIT, engine.possession == "away",
		engine.enemy_plan.get("icon", "")))
	return h

func _beast_slot(side: String, beast: Dictionary, kit: Color, has_ball: bool, intent: String) -> Control:
	var root := Control.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2(0, 320)
	root.clip_contents = false
	# arte da fera — preenche o slot inteiro (grande), centralizada
	var art := UIHelpers.beast_tex(beast.get("art", ""))
	if art != null:
		var spr := TextureRect.new()
		spr.texture = art
		spr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(spr)
		_beast_node[side] = spr
	else:
		var p := PanelContainer.new()
		p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		p.custom_minimum_size = Vector2(150, 190)
		p.add_theme_stylebox_override("panel", UIHelpers.sbf(kit, UIHelpers.BRONZE, 2, 16, 0, 0))
		var pc := CenterContainer.new(); p.add_child(pc)
		pc.add_child(UIHelpers.clbl(beast.get("crest", "?"), 64, Color.WHITE))
		root.add_child(p)
		_beast_node[side] = p
	# marcador (posse / intenção) — overlay flutuante no topo, sem roubar espaço
	var marker: Control = null
	if has_ball:
		var posse := UIHelpers.icon_tex("posse")
		if posse != null:
			var pr := TextureRect.new(); pr.texture = posse
			pr.custom_minimum_size = Vector2(72, 70)
			pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			marker = pr
		else:
			marker = _banner("⚽ POSSE DE BOLA")
	elif intent != "":
		marker = _intent(intent)
	if marker != null:
		var mc := CenterContainer.new()
		mc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		mc.offset_bottom = 72
		mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mc.add_child(marker)
		root.add_child(mc)
	return root

func _banner(txt: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIHelpers.sbf(UIHelpers.GOLD, Color("8a6a2a"), 1, 4, 8, 3))
	p.add_child(UIHelpers.clbl(txt, 9, Color("1a1206")))
	return p

func _intent(icon: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("160d05"), UIHelpers.GOLD, 2, 16, 6, 5))
	p.add_child(UIHelpers.clbl(icon, 18, UIHelpers.GOLD2))
	return p

# --- faixa inferior: energia | cartas | fim de turno ---
func _bottom() -> Control:
	# transparente: o chrome vem do bottombar_bg pintado (já tem livro/engrenagem)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 34)
	mc.add_theme_constant_override("margin_right", 26)
	mc.add_theme_constant_override("margin_top", 6)
	mc.add_theme_constant_override("margin_bottom", 12)
	mc.custom_minimum_size = Vector2(0, 150)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	mc.add_child(h)
	h.add_child(_energy_box())
	# CenterContainer (sem clipping) pra não cortar as cartas nem o hover-lift
	var hand_wrap := CenterContainer.new()
	hand_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hand_h := HBoxContainer.new(); hand_h.add_theme_constant_override("separation", 8)
	hand_h.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_wrap.add_child(hand_h)
	for i in engine.hand.size():
		hand_h.add_child(_card(i))
	h.add_child(hand_wrap)
	var endb := UIHelpers.ornate_btn("FIM DE TURNO", 15)
	endb.custom_minimum_size = Vector2(210, 79)
	endb.pressed.connect(_on_end_turn)
	if not _has_affordable_card():
		_pulse(endb)        # brilha quando não há mais o que fazer
	h.add_child(endb)
	return mc

func _small_icon(name: String) -> Control:
	var t := UIHelpers.icon_tex(name)
	if t == null:
		return null
	var r := TextureRect.new(); r.texture = t
	r.custom_minimum_size = Vector2(24, 24)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return r

func _has_affordable_card() -> bool:
	for id in engine.hand:
		if Cards.ALL[id]["cost"] <= engine.energy:
			return true
	return false

func _energy_box() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(70, 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var en_lbl := UIHelpers.tlbl("%d/%d" % [engine.energy, engine.energy_max], 24, Color("dff1ff"))
	v.add_child(en_lbl)
	if engine.energy != _prev_energy:
		_pop(en_lbl, 1.4)
	var gem := UIHelpers.icon_tex("energy")
	var gems := HBoxContainer.new(); gems.add_theme_constant_override("separation", 2)
	gems.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in engine.energy_max:
		if gem != null:
			var gr := TextureRect.new(); gr.texture = gem
			gr.custom_minimum_size = Vector2(14, 14)
			gr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			gr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			gr.modulate = Color.WHITE if i < engine.energy else Color(1, 1, 1, 0.22)
			gems.add_child(gr)
	v.add_child(gems)
	v.add_child(UIHelpers.clbl("ENERGIA", 8, Color("a9cdea")))
	return v

func _card(idx: int) -> Control:
	var id: String = engine.hand[idx]
	var c: Dictionary = Cards.ALL[id]
	var can: bool = c["cost"] <= engine.energy and not engine.busy
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(84, 118)
	btn.pivot_offset = Vector2(42, 118)     # cresce pra cima no hover
	btn.disabled = not can
	var border: Color = UIHelpers.TYPE_COL.get(c["type"], UIHelpers.BRONZE)
	btn.add_theme_stylebox_override("normal",   UIHelpers.sbf(Color("1d1409"), border, 2, 9, 0, 0))
	btn.add_theme_stylebox_override("hover",    UIHelpers.sbf(Color("261b0e"), UIHelpers.GOLD, 2, 9, 0, 0))
	btn.add_theme_stylebox_override("pressed",  UIHelpers.sbf(Color("1d1409"), UIHelpers.GOLD, 2, 9, 0, 0))
	btn.add_theme_stylebox_override("disabled", UIHelpers.sbf(Color("140e07"), Color("3c2b12"), 2, 9, 0, 0))
	btn.pressed.connect(_on_card.bind(idx, btn))
	btn.mouse_entered.connect(_hover.bind(btn, true))
	btn.mouse_exited.connect(_hover.bind(btn, false))

	var art := UIHelpers.card_tex(id)
	if art != null:
		var spr := TextureRect.new()
		spr.texture = art
		spr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(spr)
		var fr := UIHelpers.frame_tex("card_frame")
		if fr != null:
			var np := NinePatchRect.new()
			np.texture = fr
			np.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			np.patch_margin_left = 22; np.patch_margin_right = 22
			np.patch_margin_top = 22; np.patch_margin_bottom = 22
			np.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(np)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	# faixa de nome (vermelha, topo)
	var namep := PanelContainer.new()
	namep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	namep.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("8e2323"), Color("5a1414"), 1, 5, 2, 2))
	var nm := UIHelpers.clbl(c["nm"], 9, Color("fbeede"))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	namep.add_child(nm)
	v.add_child(namep)
	# meio (a arte aparece atrás; emoji no fallback)
	var midc := CenterContainer.new()
	midc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	midc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if art == null:
		midc.add_child(UIHelpers.clbl(c.get("ic", ""), 30, Color.WHITE))
	v.add_child(midc)
	# descrição (rodapé translúcido)
	var descp := PanelContainer.new()
	descp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	descp.add_theme_stylebox_override("panel", UIHelpers.sbf(Color(0, 0, 0, 0.62), Color(0, 0, 0, 0), 0, 0, 3, 2))
	var ds := UIHelpers.clbl(c.get("ds", ""), 8, UIHelpers.RUNE)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	descp.add_child(ds)
	v.add_child(descp)
	btn.add_child(v)
	UIHelpers.ignore_mouse(v)
	# custo em círculo (topo-esquerdo, por cima)
	var circ := Panel.new()
	circ.size = Vector2(26, 26); circ.position = Vector2(2, 2)
	circ.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var csb := StyleBoxFlat.new(); csb.bg_color = Color("17110b")
	csb.border_color = UIHelpers.GOLD; csb.set_border_width_all(2); csb.set_corner_radius_all(13)
	circ.add_theme_stylebox_override("panel", csb)
	var costn := UIHelpers.tlbl(str(c["cost"]), 14, UIHelpers.GOLD2)
	costn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	costn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	costn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	costn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.add_child(costn)
	btn.add_child(circ)

	# entrada (compra) — leque escalonado
	if _fresh_hand:
		btn.modulate = Color(1, 1, 1, 0)
		btn.scale = Vector2(0.7, 0.7)
		var tw := create_tween().set_parallel(true)
		var delay: float = idx * 0.06
		tw.tween_property(btn, "modulate:a", 1.0, 0.22).set_delay(delay)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.26).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return btn

# ==========================================================================
#  RESULTADO
# ==========================================================================
func _show_result() -> void:
	for c in layer.get_children():
		layer.remove_child(c)
		c.queue_free()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var pnl := UIHelpers.framed_t(28, 22)
	center.add_child(pnl)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	pnl.add_child(v)
	var won: bool = engine.winner == "home"
	v.add_child(UIHelpers.clbl("🏆" if won else "💀", 60, UIHelpers.GOLD2))
	v.add_child(UIHelpers.tlbl("VITÓRIA!" if won else "DERROTA", 32,
		UIHelpers.GOLD2 if won else Color("ff6b6b")))
	var reasons := {"KO": "por NOCAUTE de fôlego!", "TIME": "no placar final.",
		"GOLDEN": "com GOL DE OURO!", "GOLEADA": "por GOLEADA!"}
	v.add_child(UIHelpers.clbl(
		"%s venceu %s" % [engine._nm(engine.winner), reasons.get(engine.reason, "")],
		14, UIHelpers.RUNE2))
	var sc_lbl := UIHelpers.tlbl("0  x  0", 26, UIHelpers.RUNE)
	v.add_child(sc_lbl)
	var hs: int = engine.score["home"]
	var aw: int = engine.score["away"]
	var ctw := create_tween()
	ctw.tween_method(func(t: float):
		sc_lbl.text = "%d  x  %d" % [int(round(t * hs)), int(round(t * aw))],
		0.0, 1.0, 0.7).set_delay(0.3)
	var btn := UIHelpers.gold_btn("CONTINUAR")
	btn.pressed.connect(func(): match_ended.emit(won))
	v.add_child(btn)
	# entrada do painel
	pnl.scale = Vector2(0.6, 0.6)
	pnl.modulate = Color(1, 1, 1, 0)
	pnl.pivot_offset = pnl.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(pnl, "modulate:a", 1.0, 0.3)
	tw.tween_property(pnl, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ==========================================================================
#  AÇÕES
# ==========================================================================
func _on_card(idx: int, btn: Button) -> void:
	if engine.busy: return
	if idx >= engine.hand.size(): return
	if Cards.ALL[engine.hand[idx]]["cost"] > engine.energy: return
	engine.busy = true
	# anima a carta jogada: pop + sobe + encolhe (vai pro "descarte")
	btn.z_index = 10
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.25, 1.25), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(btn, "scale", Vector2(0.2, 0.2), 0.16).set_delay(0.02)
	tw.tween_property(btn, "modulate:a", 0.0, 0.18).set_delay(0.02)
	await tw.finished
	engine.busy = false
	if engine.play_card(idx):
		render()

func _on_end_turn() -> void:
	if engine.over or engine.busy: return
	engine.busy = true
	engine.end_turn()
	var events: Array = engine.turn_events.duplicate(true)
	render()
	await _play_turn_choreo(events)
	Engine.time_scale = 1.0     # garante restauração
	engine.busy = false
	if engine.over:
		_show_result()
	else:
		engine.start_turn()
		_fresh_hand = true
		render()

# ==========================================================================
#  HELPERS DE ANIMAÇÃO
# ==========================================================================
func _tween_prop(node: Object, prop: String, to, dur: float, delay: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, prop, to, dur).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _pop(node: Control, amount: float = 1.4) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(amount, amount)
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _flash(node: CanvasItem) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color(2, 2, 2, 1), 0.08)
	tw.tween_property(node, "modulate", Color.WHITE, 0.25)

func _pulse(node: CanvasItem) -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(node, "modulate", Color(1.3, 1.3, 1.1, 1), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)

func _hover(btn: Button, up: bool) -> void:
	if btn.disabled and up: return
	if btn.has_meta("htw"):
		var old = btn.get_meta("htw")
		if old is Tween and old.is_valid():
			old.kill()
	btn.z_index = 6 if up else 0
	var tw := create_tween()
	btn.set_meta("htw", tw)
	tw.tween_property(btn, "scale", Vector2(1.12, 1.12) if up else Vector2.ONE, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _toast(msg: String, col: Color) -> void:
	var t := UIHelpers.tlbl(msg, 30, col)
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 6)
	t.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	t.position = Vector2(get_viewport_rect().size.x / 2.0 - 120, 70)
	t.custom_minimum_size = Vector2(240, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(t)
	t.modulate = Color(1, 1, 1, 0)
	t.scale = Vector2(0.6, 0.6)
	t.pivot_offset = Vector2(120, 20)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(t, "modulate:a", 1.0, 0.15)
	tw.tween_property(t, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(0.7)
	tw.tween_property(t, "modulate:a", 0.0, 0.4)
	tw.tween_callback(t.queue_free)

# ==========================================================================
#  COREOGRAFIA DO TURNO (Parte 2 — drama do campo)
# ==========================================================================
func _opp_side(s: String) -> String:
	return "away" if s == "home" else "home"

## Timer em tempo REAL (ignora o slow-mo / Engine.time_scale).
func _rt(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout

func _play_turn_choreo(events: Array) -> void:
	if events.is_empty():
		await _rt(0.28)
		return
	for e in events:
		match e.get("type", ""):
			"steal":
				_toast("✋ Roubo de bola!", Color("ff9a6a"))
				_recoil(_beast_node.get(_opp_side(e["by"])))
				await _rt(0.4)
			"shot":
				await _shot_choreo(e)
	await _rt(0.15)

func _shot_choreo(e: Dictionary) -> void:
	var by: String = e["by"]
	var result: String = e.get("result", "")
	_lunge(_beast_node.get(by), by)
	await _rt(0.1)
	Engine.time_scale = 0.5          # câmera lenta (menos extrema = mais rápido)
	await _fireball(by)
	Engine.time_scale = 1.0
	if result == "goal":
		_goal_burst()
		var victim: String = e.get("victim", _opp_side(by))
		_recoil(_beast_node.get(victim))
		if e.has("drain"):
			_float_number(victim, "-%d fôlego" % e["drain"], Color("ff6b6b"))
		await _rt(0.7)
	else:
		_save_popup()
		await _rt(0.45)

func _fireball(by: String) -> void:
	var vp := get_viewport_rect().size
	var y := vp.y * 0.40
	var start_x := vp.x * (0.34 if by == "home" else 0.66)
	var goal_x := vp.x * (0.9 if by == "home" else 0.1)
	var ball := _make_ball()
	layer.add_child(ball)
	ball.position = Vector2(start_x, y)
	# rastro de fogo (aparece escalonado conforme a bola passa)
	for i in 7:
		var f := float(i + 1) / 8.0
		var tx := lerpf(start_x, goal_x, f)
		_spawn_trail(Vector2(tx, y - sin(f * PI) * 36), f * 0.45)
	var tw := create_tween()
	tw.tween_property(ball, "position:x", goal_x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var tw2 := create_tween()
	tw2.tween_property(ball, "position:y", y - 42, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw2.tween_property(ball, "position:y", y, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	ball.queue_free()

func _spawn_trail(pos: Vector2, delay: float) -> void:
	var d := _make_glow(16, Color(1, 0.55, 0.15, 0.9))
	layer.add_child(d)
	d.position = pos - Vector2(8, 8)
	d.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(d, "modulate:a", 0.85, 0.05).set_delay(delay)
	tw.tween_property(d, "modulate:a", 0.0, 0.4)
	tw.tween_callback(d.queue_free)

func _make_ball() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(30, 30)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow := _make_glow(46, Color(1, 0.5, 0.1, 0.6))
	glow.position = Vector2(-8, -8)
	c.add_child(glow)
	var b := UIHelpers.icon_tex("ball")
	if b != null:
		var tr := TextureRect.new(); tr.texture = b
		tr.size = Vector2(30, 30)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(tr)
	else:
		c.add_child(_make_glow(26, Color.WHITE))
	return c

func _make_glow(d: int, col: Color) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(d, d)
	p.size = Vector2(d, d)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(d / 2.0))
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _goal_burst() -> void:
	_screen_shake(11.0, 0.45)
	_vignette_flash(Color(1.0, 0.82, 0.35), 0.4)
	var t := UIHelpers.tlbl("G O O O L !", 60, UIHelpers.GOLD2)
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 8)
	t.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	t.position = get_viewport_rect().size / 2.0 - Vector2(180, 40)
	t.custom_minimum_size = Vector2(360, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.pivot_offset = Vector2(180, 30)
	layer.add_child(t)
	t.scale = Vector2(0.2, 0.2); t.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(t, "modulate:a", 1.0, 0.12)
	tw.tween_property(t, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_property(t, "scale", Vector2.ONE, 0.12)
	tw.tween_interval(0.6)
	tw.tween_property(t, "modulate:a", 0.0, 0.35)
	tw.tween_callback(t.queue_free)

func _save_popup() -> void:
	_screen_shake(5.0, 0.25)
	_toast("🧤 DEFENDEU!", Color("86d8ff"))

func _screen_shake(intensity: float, dur: float) -> void:
	var tw := create_tween()
	var steps := 7
	for i in steps:
		var damp := 1.0 - float(i) / float(steps)
		var off := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)) * damp
		tw.tween_property(layer, "position", off, dur / float(steps))
	tw.tween_property(layer, "position", Vector2.ZERO, dur / float(steps))

func _vignette_flash(col: Color, dur: float) -> void:
	var r := ColorRect.new()
	r.color = Color(col.r, col.g, col.b, 0.45)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = 50
	layer.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.0, dur)
	tw.tween_callback(r.queue_free)

func _lunge(node, side: String) -> void:
	if node == null or not is_instance_valid(node): return
	node.pivot_offset = node.size / 2.0
	var dir := 1.0 if side == "home" else -1.0
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, "rotation", 0.06 * dir, 0.12)
	tw.tween_property(node, "scale", Vector2.ONE, 0.22)
	tw.parallel().tween_property(node, "rotation", 0.0, 0.22)

func _recoil(node) -> void:
	if node == null or not is_instance_valid(node): return
	node.pivot_offset = node.size / 2.0
	var tw := create_tween()
	tw.tween_property(node, "rotation", 0.09, 0.05)
	tw.tween_property(node, "rotation", -0.07, 0.05)
	tw.tween_property(node, "rotation", 0.0, 0.1)
	var tw2 := create_tween()
	tw2.tween_property(node, "modulate", Color(2.2, 0.7, 0.7, 1), 0.06)
	tw2.tween_property(node, "modulate", Color.WHITE, 0.28)

func _float_number(side: String, text: String, col: Color) -> void:
	var pos: Vector2
	var node = _beast_node.get(side)
	if node != null and is_instance_valid(node):
		pos = node.global_position + Vector2(node.size.x / 2.0 - 40, node.size.y * 0.3)
	else:
		var vp := get_viewport_rect().size
		pos = Vector2(vp.x * (0.3 if side == "home" else 0.7), vp.y * 0.4)
	var l := UIHelpers.tlbl(text, 22, col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(l)
	l.position = pos
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 50, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)
