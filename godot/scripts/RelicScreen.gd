extends Control
## Tela de escolha de relíquia — mostra 3 opções, jogador escolhe 1.
const UIHelpers = preload("res://scripts/UIHelpers.gd")

signal relic_chosen(relic_id: String)

var choices: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choices = GameState.random_relic_choices(3)
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left",   24)
	root.add_theme_constant_override("margin_right",  24)
	root.add_theme_constant_override("margin_top",    24)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	root.add_child(col)

	var title_pnl := UIHelpers.framed(UIHelpers.PANEL_B, UIHelpers.GOLD)
	col.add_child(title_pnl)
	var tv := VBoxContainer.new()
	title_pnl.add_child(tv)
	tv.add_child(UIHelpers.clbl("🎁 RELÍQUIA", 22, UIHelpers.GOLD2))
	tv.add_child(UIHelpers.clbl("Escolha 1 de 3 relíquias", 11, UIHelpers.RUNE2))

	for relic_id in choices:
		col.add_child(_relic_card(relic_id))

	if choices.is_empty():
		col.add_child(UIHelpers.clbl("Nenhuma relíquia disponível!", 13, UIHelpers.RUNE2))
		var skip_btn := UIHelpers.gold_btn("Continuar")
		skip_btn.pressed.connect(func(): relic_chosen.emit(""))
		col.add_child(skip_btn)

func _relic_card(relic_id: String) -> Control:
	var data: Dictionary = GameState.RELICS[relic_id]
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 90)
	btn.add_theme_stylebox_override("normal",  UIHelpers.sbf(UIHelpers.PANEL_A, UIHelpers.BRONZE, 2, 12, 10, 8))
	btn.add_theme_stylebox_override("hover",   UIHelpers.sbf(UIHelpers.PANEL_A, UIHelpers.GOLD,   2, 12, 10, 8))
	btn.add_theme_stylebox_override("pressed", UIHelpers.sbf(UIHelpers.PANEL_B, UIHelpers.GOLD2,  2, 12, 10, 8))
	btn.pressed.connect(func(): _pick(relic_id))

	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(h)

	var ic_c := CenterContainer.new()
	ic_c.custom_minimum_size = Vector2(60, 0)
	ic_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rtex := UIHelpers.relic_tex(relic_id)
	if rtex != null:
		var rr := UIHelpers.sprite(rtex)
		rr.custom_minimum_size = Vector2(48, 48)
		ic_c.add_child(rr)
	else:
		ic_c.add_child(_ign(UIHelpers.clbl(data["ic"], 30, Color.WHITE)))
	h.add_child(ic_c)

	var tv := VBoxContainer.new()
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(_ign(UIHelpers.lbl(data["name"], 14, UIHelpers.GOLD2)))
	var desc := UIHelpers.lbl(data["desc"], 10, UIHelpers.RUNE2)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(desc)
	h.add_child(tv)

	UIHelpers.ignore_mouse(h)
	return btn

func _ign(n: Node) -> Node:
	if n is Control: (n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n

func _pick(relic_id: String) -> void:
	GameState.add_relic(relic_id)
	relic_chosen.emit(relic_id)
