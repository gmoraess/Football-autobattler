extends Control
## Tela de seleção de fera — 4 cards clicáveis, cada um com stats e lore.
const UIHelpers = preload("res://scripts/UIHelpers.gd")

signal beast_selected

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_top", 18)
	root.add_theme_constant_override("margin_bottom", 18)
	add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	root.add_child(col)

	# Título
	var title_pnl := UIHelpers.framed(UIHelpers.PANEL_B, UIHelpers.GOLD)
	col.add_child(title_pnl)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 4)
	title_pnl.add_child(tv)
	tv.add_child(UIHelpers.clbl("⚔ COPA DOS IMORTAIS", 22, UIHelpers.GOLD2))
	tv.add_child(UIHelpers.clbl("Escolha sua Fera para a jornada", 11, UIHelpers.RUNE2))

	# Grid de feras (2×2)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)

	for id in ["couraca", "gortax", "aurelio", "mandibula"]:
		grid.add_child(_beast_card(id))

	# Rodapé
	col.add_child(UIHelpers.clbl("Escolha define seu baralho inicial e Super Lance.", 10, UIHelpers.RUNE2))

func _beast_card(id: String) -> Control:
	var data: Dictionary = GameState.BEASTS[id]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 210)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_stylebox_override("normal",  UIHelpers.sbf(UIHelpers.PANEL_A, UIHelpers.BRONZE, 2, 14, 0, 0))
	btn.add_theme_stylebox_override("hover",   UIHelpers.sbf(UIHelpers.PANEL_A, UIHelpers.GOLD,   2, 14, 0, 0))
	btn.add_theme_stylebox_override("pressed", UIHelpers.sbf(UIHelpers.PANEL_B, UIHelpers.GOLD2,  2, 14, 0, 0))
	btn.pressed.connect(func(): _on_select(id))

	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)

	# crest
	var crest_c := CenterContainer.new()
	crest_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crest_pnl := PanelContainer.new()
	crest_pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest_pnl.custom_minimum_size = Vector2(80, 80)
	var sb := UIHelpers.sbf(UIHelpers.HOME_KIT, UIHelpers.BRONZE, 2, 40, 0, 0)
	crest_pnl.add_theme_stylebox_override("panel", sb)
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest_pnl.add_child(cc)
	cc.add_child(_ign(UIHelpers.clbl(data["crest"], 40, Color.WHITE)))
	crest_c.add_child(crest_pnl)
	inner.add_child(_ign(crest_c))

	inner.add_child(_ign(UIHelpers.clbl(data["name"], 16, UIHelpers.GOLD2)))

	var type_lbl := UIHelpers.clbl(data["type"], 10, UIHelpers.RUNE2)
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(type_lbl)

	var super_pnl := PanelContainer.new()
	super_pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	super_pnl.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("1a0d04"), UIHelpers.GOLD, 1, 6, 6, 3))
	super_pnl.add_child(_ign(UIHelpers.clbl("⚡ " + data["super_name"], 10, UIHelpers.GOLD2)))
	inner.add_child(_ign(super_pnl))

	var lore := UIHelpers.clbl(data["lore"], 9, UIHelpers.RUNE2)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lore_m := MarginContainer.new()
	lore_m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lore_m.add_theme_constant_override("margin_left", 8)
	lore_m.add_theme_constant_override("margin_right", 8)
	lore_m.add_child(lore)
	inner.add_child(lore_m)

	UIHelpers.ignore_mouse(inner)
	return btn

func _ign(n: Node) -> Node:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

func _on_select(id: String) -> void:
	GameState.start_run(id)
	beast_selected.emit()
