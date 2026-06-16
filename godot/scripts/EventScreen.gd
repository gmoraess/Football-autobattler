extends Control
## Tela de evento roguelike — escolha narrativa com efeito.
const UIHelpers = preload("res://scripts/UIHelpers.gd")

signal event_done(needs_relic: bool)

var event_data: Dictionary = {}
var pending_relic: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Escolhe evento aleatório
	event_data = GameState.EVENTS[randi() % GameState.EVENTS.size()]
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]:
		root.add_theme_constant_override(side, 28)
	add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	root.add_child(col)

	# Ícone de evento
	col.add_child(UIHelpers.clbl("❓", 48, UIHelpers.GOLD2))

	# Título e texto
	var pnl := UIHelpers.framed(UIHelpers.PANEL_B, UIHelpers.GOLD)
	col.add_child(pnl)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 8)
	pnl.add_child(tv)
	tv.add_child(UIHelpers.clbl(event_data.get("title","Evento"), 16, UIHelpers.GOLD2))
	var txt_lbl := UIHelpers.clbl(event_data.get("text",""), 12, UIHelpers.RUNE)
	txt_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(txt_lbl)

	# Escolhas
	col.add_child(UIHelpers.clbl("O QUE FAZER?", 10, UIHelpers.RUNE2))
	for choice in event_data.get("choices", []):
		col.add_child(_choice_btn(choice))

func _choice_btn(choice: Dictionary) -> Button:
	var btn := UIHelpers.gold_btn(choice.get("label","?"))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.pressed.connect(func(): _apply(choice))
	return btn

func _apply(choice: Dictionary) -> void:
	pending_relic = false
	match choice.get("effect", "nothing"):
		"add_card":
			GameState.add_card(choice.get("card", "passe"))
		"gold":
			GameState.gold = maxi(0, GameState.gold + choice.get("val", 0))
		"heal":
			GameState.sta_bonus += choice.get("val", 0)
		"gold_sta":
			GameState.gold = maxi(0, GameState.gold + choice.get("gold", 0))
			GameState.sta_bonus += choice.get("sta", 0)
		"sta_relic":
			GameState.sta_bonus += choice.get("val", 0)
			pending_relic = true
		_:
			pass  # "nothing"
	event_done.emit(pending_relic)
