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
		shade.color = Color(0, 0, 0, 0.28)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
	else:
		var bg := ColorRect.new()
		bg.color = UIHelpers.STONE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	layer = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	_start_match()

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
	var mid := _arena_row()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mid)
	col.add_child(_bottom())

	_sync_prev()        # depois de montar, o "anterior" passa a ser o estado atual
	_fresh_hand = false

# --- placar superior ---
func _scoreboard() -> Control:
	var panel := UIHelpers.framed_t(12, 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	panel.add_child(h)
	h.add_child(_team_head("home"))
	var mid := VBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.custom_minimum_size = Vector2(170, 0)
	var score_lbl := UIHelpers.tlbl("%d : %d" % [engine.score["home"], engine.score["away"]], 34, UIHelpers.GOLD2)
	mid.add_child(score_lbl)
	if engine.score["home"] != _prev_score["home"] or engine.score["away"] != _prev_score["away"]:
		_pop(score_lbl, 1.5)
	var trn := "TURNO %d / %d" % [mini(engine.turn, MatchEngine.TURNS), MatchEngine.TURNS]
	if engine.sudden_death: trn += " · MORTE SÚBITA"
	mid.add_child(UIHelpers.clbl(trn, 10, UIHelpers.RUNE2))
	mid.add_child(_minimap())
	h.add_child(mid)
	h.add_child(_team_head("away"))
	return panel

func _crest_rect() -> Control:
	var crest := UIHelpers.frame_tex("banner_crest")
	if crest == null:
		return null
	var cr := TextureRect.new()
	cr.texture = crest
	cr.custom_minimum_size = Vector2(36, 30)
	cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return cr

func _team_head(side: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var kit: Color = UIHelpers.HOME_KIT if side == "home" else UIHelpers.AWAY_KIT
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var nl := UIHelpers.tlbl(engine._nm(side), 15, kit)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cr := _crest_rect()
	if side == "home":
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if cr != null: row.add_child(cr)
		row.add_child(nl)
	else:
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(nl)
		if cr != null: row.add_child(cr)
	v.add_child(row)
	var frac: float = float(engine.sta[side]) / float(engine.sta_max[side])
	v.add_child(UIHelpers.meter(frac, UIHelpers.STA_COL, "FÔLEGO %d/%d" % [engine.sta[side], engine.sta_max[side]], 200))
	return v

func _minimap() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(150, 56)
	var field := ColorRect.new(); field.color = Color("236e34")
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(field)
	var ml := ColorRect.new(); ml.color = Color(1, 1, 1, 0.35)
	ml.position = Vector2(74, 3); ml.size = Vector2(1, 50); c.add_child(ml)
	var hp := [[18, 28], [18, 50], [32, 39], [44, 28], [44, 50]]
	var ap := [[56, 28], [56, 50], [68, 39], [82, 28], [82, 50]]
	for pos in hp: _dot(c, pos[0], pos[1], UIHelpers.HOME_KIT)
	for pos in ap: _dot(c, pos[0], pos[1], UIHelpers.AWAY_KIT)
	var bx: float = 38 if engine.possession == "home" else 62
	var ball := ColorRect.new(); ball.color = Color.WHITE
	ball.size = Vector2(7, 7); ball.position = Vector2(bx / 100.0 * 150 - 3, 0.5 * 56 - 3)
	c.add_child(ball)
	return c

func _dot(parent: Control, xp: int, yp: int, col: Color) -> void:
	var r := ColorRect.new(); r.color = col; r.size = Vector2(8, 8)
	r.position = Vector2(float(xp) / 100.0 * 150 - 4, float(yp) / 100.0 * 56 - 4)
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

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel",
		UIHelpers.sbt("panel", 28, 8, 6, UIHelpers.PANEL_B, UIHelpers.GOLD if active else Color("3c2b12")))
	if not active: box.modulate = Color(1, 1, 1, 0.5)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 3); box.add_child(v)
	var hd := HBoxContainer.new(); hd.add_theme_constant_override("separation", 6)
	var ic := UIHelpers.icon_tex(STAT_ICON[key])
	if ic != null:
		var ir := TextureRect.new(); ir.texture = ic
		ir.custom_minimum_size = Vector2(20, 20)
		ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hd.add_child(ir)
	var nl := UIHelpers.lbl(name, 11, UIHelpers.BAR_TXT[key])
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(nl)
	hd.add_child(UIHelpers.lbl("%d/%d" % [cur, mx], 9, UIHelpers.RUNE2))
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
	v.add_child(dl)
	return box

func _beasts_center() -> Control:
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(_beast_slot(engine.home, UIHelpers.HOME_KIT, engine.possession == "home", ""))
	h.add_child(_beast_slot(engine.away, UIHelpers.AWAY_KIT, engine.possession == "away",
		engine.enemy_plan.get("icon", "")))
	return h

func _beast_slot(beast: Dictionary, kit: Color, has_ball: bool, intent: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_END
	var top := CenterContainer.new()
	top.custom_minimum_size = Vector2(0, 30)
	if has_ball:
		var posse := UIHelpers.icon_tex("posse")
		if posse != null:
			var pr := TextureRect.new(); pr.texture = posse
			pr.custom_minimum_size = Vector2(48, 28)
			pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			top.add_child(pr)
		else:
			top.add_child(_banner("⚽ POSSE"))
	elif intent != "":
		top.add_child(_intent(intent))
	v.add_child(top)
	var art := UIHelpers.beast_tex(beast.get("art", ""))
	if art != null:
		var spr := UIHelpers.sprite(art)
		spr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spr.custom_minimum_size = Vector2(0, 220)
		v.add_child(spr)
	else:
		var cc := CenterContainer.new()
		cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(120, 150)
		p.add_theme_stylebox_override("panel", UIHelpers.sbf(kit, UIHelpers.BRONZE, 2, 14, 0, 0))
		var pc := CenterContainer.new(); p.add_child(pc)
		pc.add_child(UIHelpers.clbl(beast.get("crest", "?"), 56, Color.WHITE))
		cc.add_child(p)
		v.add_child(cc)
	return v

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
	var panel := UIHelpers.framed_t(10, 6)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)
	h.add_child(_energy_box())
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 156)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hand_h := HBoxContainer.new(); hand_h.add_theme_constant_override("separation", 6)
	hand_h.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(hand_h)
	for i in engine.hand.size():
		hand_h.add_child(_card(i))
	h.add_child(scroll)
	var endb := UIHelpers.gold_btn("FIM DE TURNO")
	endb.custom_minimum_size = Vector2(150, 0)
	endb.add_theme_font_size_override("font_size", 16)
	endb.pressed.connect(_on_end_turn)
	if not _has_affordable_card():
		_pulse(endb)        # brilha quando não há mais o que fazer
	h.add_child(endb)
	return panel

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
	btn.custom_minimum_size = Vector2(96, 138)
	btn.pivot_offset = Vector2(48, 138)     # cresce pra cima no hover
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
	v.add_theme_constant_override("separation", 1)
	var cost_lbl := UIHelpers.clbl("⚡%d" % c["cost"], 12, UIHelpers.GOLD2)
	cost_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	cost_lbl.add_theme_constant_override("outline_size", 4)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(cost_lbl)
	if art == null:
		v.add_child(UIHelpers.clbl(c.get("ic", ""), 26, Color.WHITE))
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var name_lbl := UIHelpers.clbl(c["nm"], 10, UIHelpers.RUNE)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 4)
	v.add_child(name_lbl)
	var ds := UIHelpers.clbl(c.get("ds", ""), 8, UIHelpers.RUNE2)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.add_theme_color_override("font_outline_color", Color.BLACK)
	ds.add_theme_constant_override("outline_size", 3)
	v.add_child(ds)
	btn.add_child(v)
	UIHelpers.ignore_mouse(v)

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
	v.add_child(UIHelpers.tlbl("%d  x  %d" % [engine.score["home"], engine.score["away"]], 26, UIHelpers.RUNE))
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
	var pre_score := {"home": engine.score["home"], "away": engine.score["away"]}
	var pre_poss: String = engine.possession
	engine.end_turn()
	render()
	# toasts de eventos do turno
	if engine.score["home"] > pre_score["home"] or engine.score["away"] > pre_score["away"]:
		_toast("⚽ GOOOL!", UIHelpers.GOLD2)
	elif engine.possession != pre_poss:
		_toast("✋ Roubo de bola!", Color("ff8f8f"))
	await get_tree().create_timer(0.8).timeout
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
