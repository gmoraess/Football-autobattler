extends Control
## Tela do mapa roguelike — 3 atos, 4 colunas por ato, 3 raias.
const UIHelpers = preload("res://scripts/UIHelpers.gd")
## Mostra a posição atual e destaca os nós alcançáveis.

signal node_chosen(target_col: int, target_lane: int)

const NODE_ICONS := {
	"partida": "⚽", "elite": "💀", "bau": "🎁",
	"evento": "❓",  "loja": "🛒",  "boss": "👑",
}
const NODE_COLORS := {
	"partida": Color("1e4a1e"), "elite": Color("4a1e1e"), "bau": Color("2a3a1a"),
	"evento":  Color("1e2a4a"), "loja":  Color("2a2a1e"), "boss": Color("3a1a0a"),
}
const NODE_BORDER := {
	"partida": Color("3aa83a"), "elite": Color("c83a3a"), "bau": Color("8ac83a"),
	"evento":  Color("3a8ac8"), "loja":  Color("c8c83a"), "boss": Color("d8b25a"),
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	for c in get_children(): c.free()

	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 12)
	root.add_theme_constant_override("margin_right", 12)
	root.add_theme_constant_override("margin_top", 12)
	root.add_theme_constant_override("margin_bottom", 12)
	add_child(root)

	var main_col := VBoxContainer.new()
	main_col.add_theme_constant_override("separation", 10)
	root.add_child(main_col)

	# --- Header: info da corrida ---
	main_col.add_child(_header())

	# --- Separador de ato ---
	main_col.add_child(UIHelpers.clbl(
		"━━━━  ATO %d / 3  ━━━━" % (GameState.act + 1), 11, UIHelpers.GOLD))

	# --- Mapa do ato atual ---
	main_col.add_child(_act_map())

	# --- Rodapé: dica ---
	var tip_txt := "Clique num nó iluminado para avançar."
	if GameState.col == -1:
		tip_txt = "Escolha por onde entrar no ato."
	main_col.add_child(UIHelpers.clbl(tip_txt, 10, UIHelpers.RUNE2))

func _header() -> Control:
	var pnl := UIHelpers.framed()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	pnl.add_child(h)

	# fera
	var bst_v := VBoxContainer.new()
	bst_v.add_child(UIHelpers.clbl(GameState.beast.get("crest","?"), 24, Color.WHITE))
	bst_v.add_child(UIHelpers.clbl(GameState.beast.get("name",""), 11, UIHelpers.GOLD2))
	h.add_child(bst_v)

	# relíquias
	var rel_v := VBoxContainer.new()
	rel_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rel_v.add_child(UIHelpers.lbl("Relíquias:", 9, UIHelpers.RUNE2))
	var rel_h := HBoxContainer.new()
	rel_h.add_theme_constant_override("separation", 4)
	if GameState.relics.is_empty():
		rel_h.add_child(UIHelpers.lbl("—", 9, UIHelpers.RUNE2))
	for r in GameState.relics:
		rel_h.add_child(UIHelpers.lbl(GameState.RELICS[r]["ic"] + " " + GameState.RELICS[r]["name"], 9, UIHelpers.RUNE))
	rel_v.add_child(rel_h)
	h.add_child(rel_v)

	# ouro + vida
	var stat_v := VBoxContainer.new()
	stat_v.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_v.add_child(UIHelpers.clbl("🪙 %d" % GameState.gold, 13, UIHelpers.GOLD2))
	var life_txt := "❤️ Repescagem" if GameState.extra_life else "💀 Sem repescagem"
	stat_v.add_child(UIHelpers.clbl(life_txt, 9, Color("88ff88") if GameState.extra_life else Color("ff6666")))
	h.add_child(stat_v)

	return pnl

func _act_map() -> Control:
	var act_data: Array = GameState.map_data[GameState.act]
	var reachable: Array = GameState.reachable_next()

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 520)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	for c_idx in act_data.size():
		var col_nodes: Array = act_data[c_idx]
		row.add_child(_col_panel(c_idx, col_nodes, reachable))

	return scroll

func _col_panel(c_idx: int, nodes: Array, reachable: Array) -> Control:
	var is_boss_col: bool = nodes.size() == 1
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# label coluna
	var col_labels := ["ENTRADA", "CAMINHO", "PRÉ-BOSS", "CHEFE"]
	var cl := UIHelpers.clbl(col_labels[mini(c_idx, 3)], 8, UIHelpers.RUNE2)
	vbox.add_child(cl)

	if is_boss_col:
		# boss — ocupa o centro vertical
		for _pad in 1:
			var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 60); vbox.add_child(sp)
		vbox.add_child(_node_btn(c_idx, 0, nodes[0], reachable))
		var sp2 := Control.new(); sp2.custom_minimum_size = Vector2(0, 60); vbox.add_child(sp2)
	else:
		for l in nodes.size():
			vbox.add_child(_node_btn(c_idx, l, nodes[l], reachable))

	return vbox

func _node_btn(c_idx: int, l_idx: int, node: Dictionary, reachable: Array) -> Control:
	var tp: String = node.get("type", "partida")
	var visited: bool = node.get("visited", false)
	var is_current: bool = (c_idx == GameState.col and
							(l_idx == GameState.lane or map_data_is_boss(c_idx)))

	# É alcançável?
	var can_click := false
	for pair in reachable:
		if pair[0] == c_idx and pair[1] == l_idx:
			can_click = true
			break

	var bg_col: Color
	var border_col: Color
	if is_current:
		bg_col = Color(NODE_COLORS.get(tp, UIHelpers.PANEL_A)).lightened(0.2)
		border_col = UIHelpers.GOLD2
	elif visited:
		bg_col = Color(NODE_COLORS.get(tp, UIHelpers.PANEL_A)).darkened(0.4)
		border_col = Color("3a2a18")
	elif can_click:
		bg_col = NODE_COLORS.get(tp, UIHelpers.PANEL_A)
		border_col = NODE_BORDER.get(tp, UIHelpers.GOLD)
	else:
		bg_col = Color(NODE_COLORS.get(tp, UIHelpers.PANEL_A)).darkened(0.5)
		border_col = Color("2a1a08")

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 130)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = not can_click
	btn.add_theme_stylebox_override("normal",   UIHelpers.sbf(bg_col, border_col, 2, 12, 4, 4))
	btn.add_theme_stylebox_override("hover",    UIHelpers.sbf(bg_col.lightened(0.1), UIHelpers.GOLD2, 2, 12, 4, 4))
	btn.add_theme_stylebox_override("pressed",  UIHelpers.sbf(bg_col, UIHelpers.GOLD,  2, 12, 4, 4))
	btn.add_theme_stylebox_override("disabled", UIHelpers.sbf(bg_col, border_col, 1, 12, 4, 4))
	btn.modulate = Color(1, 1, 1, 0.45) if (visited and not is_current) else Color.WHITE
	btn.pressed.connect(func(): _on_node(c_idx, l_idx))

	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 3)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)

	var ntex := UIHelpers.icon_tex("node_" + tp)
	if ntex != null:
		var nr := TextureRect.new()
		nr.texture = ntex
		nr.custom_minimum_size = Vector2(40, 40)
		nr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		nr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		nr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(nr)
	else:
		inner.add_child(UIHelpers.clbl(NODE_ICONS.get(tp, "?"), 26, Color.WHITE))
	inner.add_child(UIHelpers.clbl(tp.to_upper(), 9, UIHelpers.RUNE2))

	# nome do inimigo (para nós de luta)
	var enemy: Dictionary = node.get("enemy", {})
	if not enemy.is_empty():
		var nm_lbl := UIHelpers.clbl(enemy.get("crest","") + " " + enemy.get("name",""), 8, UIHelpers.RUNE)
		nm_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(nm_lbl)

	# diff
	if node.has("diff"):
		var diff_f: float = node["diff"]
		var diff_col: Color = Color("88ff88") if diff_f < 0.9 else (Color("ffcc44") if diff_f < 1.2 else Color("ff6666"))
		inner.add_child(UIHelpers.clbl("dif %.2f" % diff_f, 8, diff_col))

	if is_current:
		inner.add_child(UIHelpers.clbl("← VOCÊ", 8, UIHelpers.GOLD2))

	UIHelpers.ignore_mouse(inner)
	return btn

func map_data_is_boss(c_idx: int) -> bool:
	if GameState.act >= GameState.map_data.size(): return false
	return GameState.map_data[GameState.act][c_idx].size() == 1

func _on_node(target_col: int, target_lane: int) -> void:
	node_chosen.emit(target_col, target_lane)
