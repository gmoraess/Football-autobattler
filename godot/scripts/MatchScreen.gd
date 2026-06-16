extends Control
## HUD da partida + driver do MatchEngine. Tema arena gótica.
const UIHelpers = preload("res://scripts/UIHelpers.gd")
const Cards = preload("res://scripts/Cards.gd")
const MatchEngine = preload("res://scripts/MatchEngine.gd")
## Lê o estado da corrida de GameState para montar o combate.

signal match_ended(won: bool)

var engine: MatchEngine
var panel_root: MarginContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	panel_root = MarginContainer.new()
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.add_theme_constant_override("margin_left", 10)
	panel_root.add_theme_constant_override("margin_right", 10)
	panel_root.add_theme_constant_override("margin_top", 10)
	panel_root.add_theme_constant_override("margin_bottom", 10)
	add_child(panel_root)
	_start_match()

func _start_match() -> void:
	var node: Dictionary = GameState.current_node
	var home: Dictionary = {
		"name": GameState.beast.get("name", "Couraça"),
		"crest": GameState.beast.get("crest", "🛡"),
		"super": GameState.beast.get("super", "casco"),
	}
	var enemy: Dictionary = node.get("enemy", {})
	if enemy.is_empty():
		enemy = {"name": "Oponente", "crest": "?", "super": ""}
	var away: Dictionary = {
		"name": enemy.get("name", "Oponente"),
		"crest": enemy.get("crest", "?"),
		"super": enemy.get("super", ""),
	}
	var pdeck: Array = GameState.deck.duplicate()
	var odeck: Array = GameState.enemy_deck(node.get("deck_key", "normal"))
	var diff: float = node.get("diff", 1.0)
	var mods: Dictionary = GameState.get_relic_mods()

	engine = MatchEngine.new()
	engine.begin(home, away, pdeck, odeck, diff, mods)
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

	var won: bool = engine.winner == "home"
	v.add_child(UIHelpers.clbl("🏆" if won else "💀", 60, UIHelpers.GOLD2))
	v.add_child(UIHelpers.clbl("VITÓRIA!" if won else "Derrota", 30,
		UIHelpers.GOLD2 if won else Color("ff6b6b")))

	var reasons := {"KO":"por NOCAUTE de fôlego!", "TIME":"no placar final.",
	                "GOLDEN":"com GOL DE OURO!", "GOLEADA":"por GOLEADA!"}
	v.add_child(UIHelpers.clbl(
		"%s venceu %s" % [engine._nm(engine.winner), reasons.get(engine.reason,"")],
		14, UIHelpers.RUNE2))
	v.add_child(UIHelpers.clbl(
		"%d  x  %d" % [engine.score["home"], engine.score["away"]], 24, UIHelpers.RUNE))

	var btn := UIHelpers.gold_btn("▶ Continuar")
	btn.pressed.connect(func(): match_ended.emit(won))
	v.add_child(btn)

# --- barra de topo ---
func _top_bar() -> Control:
	var h := HBoxContainer.new()
	var title_txt := "⚔ %s  VS  %s" % [engine.home.get("name","?"), engine.away.get("name","?")]
	var title := UIHelpers.lbl(title_txt, 12, UIHelpers.GOLD2)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(title)
	# tipo de nó
	var tp: String = GameState.current_node.get("type","")
	var tp_icons: Dictionary = {"elite":"💀 ELITE","boss":"👑 CHEFE","partida":"⚽","bau":"🎁","evento":"❓","loja":"🛒"}
	h.add_child(UIHelpers.lbl(tp_icons.get(tp,""), 11, UIHelpers.GOLD))
	return h

# --- placar + fôlego + minimapa ---
func _scoreboard() -> Control:
	var panel := UIHelpers.framed()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	panel.add_child(h)
	h.add_child(_team_col("home"))
	var mid := VBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(UIHelpers.clbl("%d : %d" % [engine.score["home"], engine.score["away"]], 30, UIHelpers.GOLD2))
	var trn := "TURNO %d / %d" % [mini(engine.turn, MatchEngine.TURNS), MatchEngine.TURNS]
	if engine.sudden_death: trn += " · MORTE SÚBITA"
	mid.add_child(UIHelpers.clbl(trn, 9, UIHelpers.RUNE2))
	mid.add_child(_minimap())
	h.add_child(mid)
	h.add_child(_team_col("away"))
	return panel

func _team_col(side: String) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var kit: Color = UIHelpers.HOME_KIT if side == "home" else UIHelpers.AWAY_KIT
	var nm: String = engine._nm(side) + ("  (você)" if side == "home" else "")
	var nl := UIHelpers.lbl(nm, 12, UIHelpers.RUNE)
	nl.add_theme_color_override("font_color", kit)
	v.add_child(nl)
	var frac: float = float(engine.sta[side]) / float(engine.sta_max[side])
	v.add_child(UIHelpers.meter(frac, UIHelpers.STA_COL,
		"%d/%d" % [engine.sta[side], engine.sta_max[side]], 170))
	if side == "away":
		v.alignment = BoxContainer.ALIGNMENT_END
	return v

func _minimap() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(132, 60)
	var field := ColorRect.new(); field.color = Color("236e34")
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(field)
	var ml := ColorRect.new(); ml.color = Color(1,1,1,0.35)
	ml.position = Vector2(65,3); ml.size = Vector2(1,54); c.add_child(ml)
	var hp := [[18,30],[18,55],[30,42],[42,30],[42,55]]
	var ap := [[58,30],[58,55],[70,42],[82,30],[82,55]]
	for pos in hp: _dot(c, pos[0], pos[1], UIHelpers.HOME_KIT)
	for pos in ap: _dot(c, pos[0], pos[1], UIHelpers.AWAY_KIT)
	var bx: float = 34 if engine.possession == "home" else 62
	var ball := ColorRect.new(); ball.color = Color.WHITE
	ball.size = Vector2(7,7); ball.position = Vector2(bx/100.0*132-3, 0.42*60-3)
	c.add_child(ball)
	return c

func _dot(parent: Control, xp: int, yp: int, col: Color) -> void:
	var r := ColorRect.new(); r.color = col; r.size = Vector2(8,8)
	r.position = Vector2(float(xp)/100.0*132-4, float(yp)/100.0*60-4)
	parent.add_child(r)

# --- arena: barras | personagens | barras ---
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
	v.add_child(_bar(side,"F","🎯 FINALIZAÇÃO","Encher → chuta ao gol",b["F"],bm["F"],has))
	v.add_child(_bar(side,"C","⚽ CONTROLE","Mantém a posse",b["C"],MatchEngine.CD_CAP,has))
	v.add_child(_bar(side,"D","🦵 DESARME","Rouba a bola",b["D"],MatchEngine.CD_CAP,not has))
	v.add_child(_bar(side,"E","🛡 DEFESA","Bloqueia chute (guard.: %d)" % engine.saves[side],b["E"],bm["E"],not has))
	return v

func _bar(side: String, key: String, name: String, desc: String, cur: int, mx: int, active: bool) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel",
		UIHelpers.sbf(UIHelpers.PANEL_B, UIHelpers.GOLD if active else Color("3c2b12"), 1, 9, 8, 6))
	if not active: box.modulate = Color(1,1,1,0.45)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 3); box.add_child(v)
	var hd := HBoxContainer.new()
	var nl := UIHelpers.lbl(name, 9, UIHelpers.BAR_TXT[key])
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hd.add_child(nl)
	hd.add_child(UIHelpers.lbl("%d/%d" % [cur,mx], 9, UIHelpers.RUNE2)); v.add_child(hd)
	var segs := HBoxContainer.new(); segs.add_theme_constant_override("separation", 2)
	var fill := int(round(clampf(float(cur)/float(maxi(1,mx)),0.0,1.0)*14.0))
	for i in 14:
		var r := ColorRect.new(); r.custom_minimum_size = Vector2(0,9)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.color = UIHelpers.BAR_COL[key] if i < fill else UIHelpers.SEG_OFF
		segs.add_child(r)
	v.add_child(segs)
	var dl := UIHelpers.lbl(desc, 8, UIHelpers.RUNE2)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(dl)
	return box

func _center_chars() -> Control:
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.custom_minimum_size = Vector2(108, 0)
	v.add_theme_constant_override("separation", 16)
	var hc := VBoxContainer.new(); hc.alignment = BoxContainer.ALIGNMENT_CENTER
	if engine.possession == "home": hc.add_child(_banner("⚽ POSSE DE BOLA"))
	hc.add_child(_beast_panel(engine.home, UIHelpers.HOME_KIT))
	if engine.possession == "home": hc.add_child(UIHelpers.clbl("⚽", 16, Color.WHITE))
	v.add_child(hc)
	var ac := VBoxContainer.new(); ac.alignment = BoxContainer.ALIGNMENT_CENTER
	if engine.enemy_plan.get("icon","") != "":
		ac.add_child(_intent(engine.enemy_plan["icon"]))
	ac.add_child(_beast_panel(engine.away, UIHelpers.AWAY_KIT))
	if engine.possession == "away": ac.add_child(UIHelpers.clbl("⚽", 16, Color.WHITE))
	v.add_child(ac)
	return v

func _beast_panel(beast: Dictionary, kit: Color) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(74, 86)
	var sb := UIHelpers.sbf(kit, UIHelpers.BRONZE, 2, 9, 0, 0)
	sb.corner_radius_top_left = 36; sb.corner_radius_top_right = 36
	p.add_theme_stylebox_override("panel", sb)
	var cc := CenterContainer.new(); p.add_child(cc)
	cc.add_child(UIHelpers.clbl(beast.get("crest","?"), 38, Color.WHITE))
	return p

func _banner(txt: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIHelpers.sbf(UIHelpers.GOLD, Color("8a6a2a"), 1, 4, 8, 3))
	p.add_child(UIHelpers.clbl(txt, 9, Color("1a1206"))); return p

func _intent(icon: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("160d05"), UIHelpers.GOLD, 2, 16, 5, 5))
	p.add_child(UIHelpers.clbl(icon, 18, UIHelpers.GOLD2)); return p

# --- faixa inferior ---
func _bottom() -> Control:
	var panel := UIHelpers.framed()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10); panel.add_child(h)
	# energia
	var ebox := PanelContainer.new(); ebox.custom_minimum_size = Vector2(62,0)
	ebox.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("12203f"), UIHelpers.BRONZE, 1, 10, 6, 6))
	var ev := VBoxContainer.new(); ev.alignment = BoxContainer.ALIGNMENT_CENTER; ebox.add_child(ev)
	ev.add_child(UIHelpers.clbl("%d/%d" % [engine.energy, engine.energy_max], 22, Color("dff1ff")))
	ev.add_child(UIHelpers.clbl("ENERGIA", 8, Color("a9cdea"))); h.add_child(ebox)
	# mão
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0,120)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hand_h := HBoxContainer.new(); hand_h.add_theme_constant_override("separation",6)
	scroll.add_child(hand_h)
	for i in engine.hand.size(): hand_h.add_child(_card(i))
	h.add_child(scroll)
	# ações
	var av := VBoxContainer.new()
	av.custom_minimum_size = Vector2(112,0); av.alignment = BoxContainer.ALIGNMENT_CENTER
	av.add_theme_constant_override("separation", 6)
	if engine.super_name != "":
		var ready := engine.fury >= 100
		var sbtn := Button.new()
		sbtn.text = "⚡ SUPER %d%%" % engine.fury
		sbtn.add_theme_font_size_override("font_size", 12)
		var armed := engine.super_armed != ""
		var scol: Color = UIHelpers.GOLD if armed else (Color("9a5bff") if ready else Color("2a1f3e"))
		sbtn.add_theme_stylebox_override("normal",  UIHelpers.sbf(scol, UIHelpers.GOLD if ready else Color("7a3df5"), 1, 9, 8, 8))
		sbtn.add_theme_stylebox_override("hover",   UIHelpers.sbf(scol.lightened(0.1), UIHelpers.GOLD, 1, 9, 8, 8))
		sbtn.add_theme_stylebox_override("pressed", UIHelpers.sbf(scol, UIHelpers.GOLD, 1, 9, 8, 8))
		sbtn.pressed.connect(_on_super); av.add_child(sbtn)
	var endb := UIHelpers.gold_btn("▶ FIM DE TURNO")
	endb.pressed.connect(_on_end_turn); av.add_child(endb); h.add_child(av)
	return panel

func _card(idx: int) -> Control:
	var id: String = engine.hand[idx]
	var c: Dictionary = Cards.ALL[id]
	var can: bool = c["cost"] <= engine.energy and not engine.busy
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(84,110); btn.disabled = not can
	var border: Color = UIHelpers.TYPE_COL.get(c["type"], UIHelpers.BRONZE)
	btn.add_theme_stylebox_override("normal",   UIHelpers.sbf(Color("1d1409"), border, 2, 9, 4, 4))
	btn.add_theme_stylebox_override("hover",    UIHelpers.sbf(Color("261b0e"), UIHelpers.GOLD, 2, 9, 4, 4))
	btn.add_theme_stylebox_override("pressed",  UIHelpers.sbf(Color("1d1409"), UIHelpers.GOLD, 2, 9, 4, 4))
	btn.add_theme_stylebox_override("disabled", UIHelpers.sbf(Color("140e07"), Color("3c2b12"), 2, 9, 4, 4))
	btn.pressed.connect(_on_card.bind(idx))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	v.add_child(UIHelpers.clbl("⚡%d" % c["cost"], 11, UIHelpers.GOLD2))
	v.add_child(UIHelpers.clbl(c.get("ic",""), 22, Color.WHITE))
	v.add_child(UIHelpers.clbl(c["nm"], 9, UIHelpers.RUNE))
	var ds := UIHelpers.clbl(c.get("ds",""), 8, UIHelpers.RUNE2)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(ds)
	btn.add_child(v); UIHelpers.ignore_mouse(v)
	return btn

func _log_box() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("0c0805"), Color("3c2b12"), 1, 8, 8, 6))
	var v := VBoxContainer.new(); p.add_child(v)
	var lines: Array = engine.logs.slice(maxi(0, engine.logs.size()-3))
	if lines.is_empty():
		lines = ["Encha as barras com cartas. Posse: Finalização + Controle."]
	for line in lines: v.add_child(UIHelpers.lbl(line, 10, UIHelpers.RUNE2))
	return p

# ==========================================================================
#  AÇÕES
# ==========================================================================
func _on_card(idx: int) -> void:
	if engine.busy: return
	if engine.play_card(idx): render()

func _on_super() -> void:
	if engine.busy: return
	engine.arm_super(); render()

func _on_end_turn() -> void:
	if engine.over or engine.busy: return
	engine.busy = true
	engine.end_turn()
	render()
	await get_tree().create_timer(0.8).timeout
	engine.busy = false
	if engine.over:
		_show_result()
	else:
		engine.start_turn()
		render()
