extends Control
## Router principal — gerencia transições entre telas da campanha.
const UIHelpers = preload("res://scripts/UIHelpers.gd")
const BeastSelectScreen = preload("res://scripts/BeastSelectScreen.gd")
const MapScreen = preload("res://scripts/MapScreen.gd")
const MatchScreen = preload("res://scripts/MatchScreen.gd")
const RelicScreen = preload("res://scripts/RelicScreen.gd")
const EventScreen = preload("res://scripts/EventScreen.gd")
const ShopScreen = preload("res://scripts/ShopScreen.gd")

var current_screen: Control = null

func _ready() -> void:
	randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIHelpers.make_theme()
	_show_beast_select()

# ==========================================================================
#  TROCA DE TELAS
# ==========================================================================

func _show_beast_select() -> void:
	_switch_to(BeastSelectScreen.new(), {
		"beast_selected": _on_beast_selected,
	})

func _show_map() -> void:
	_switch_to(MapScreen.new(), {
		"node_chosen": _on_node_chosen,
	})

func _show_match() -> void:
	_switch_to(MatchScreen.new(), {
		"match_ended": _on_match_ended,
	})

func _show_relic(after: Callable) -> void:
	var s := RelicScreen.new()
	_switch_to(s, {"relic_chosen": after})

func _show_event() -> void:
	_switch_to(EventScreen.new(), {
		"event_done": _on_event_done,
	})

func _show_end(victory: bool) -> void:
	_clear_screen()
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	center.add_child(v)

	if victory:
		v.add_child(UIHelpers.clbl("🏆", 64, UIHelpers.GOLD2))
		v.add_child(UIHelpers.clbl("CAMPEÃO DOS IMORTAIS!", 28, UIHelpers.GOLD2))
		v.add_child(UIHelpers.clbl(
			"%s conquistou a Copa!" % GameState.beast.get("name",""), 14, UIHelpers.RUNE))
	else:
		v.add_child(UIHelpers.clbl("💀", 64, Color("ff4444")))
		v.add_child(UIHelpers.clbl("A JORNADA TERMINA AQUI", 24, Color("ff6b6b")))
		v.add_child(UIHelpers.clbl(
			"%s foi derrotado." % GameState.beast.get("name",""), 14, UIHelpers.RUNE2))

	var gold_lbl := UIHelpers.clbl("🪙 Ouro final: %d" % GameState.gold, 13, UIHelpers.GOLD)
	v.add_child(gold_lbl)

	var btn := UIHelpers.gold_btn("↻  JOGAR DE NOVO")
	btn.pressed.connect(_show_beast_select)
	v.add_child(btn)

func _show_act_clear(new_act: int) -> void:
	_clear_screen()
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER; v.add_theme_constant_override("separation", 14); cc.add_child(v)
	v.add_child(UIHelpers.clbl("👑", 56, UIHelpers.GOLD2))
	v.add_child(UIHelpers.clbl("ATO %d COMPLETO!" % new_act, 26, UIHelpers.GOLD2))
	v.add_child(UIHelpers.clbl("Próximo ato: %d / 3" % (new_act + 1), 13, UIHelpers.RUNE2))
	var btn := UIHelpers.gold_btn("Avançar para o Ato %d" % (new_act + 1))
	btn.pressed.connect(_show_map); v.add_child(btn)

func _show_repechage() -> void:
	_clear_screen()
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER; v.add_theme_constant_override("separation", 14); cc.add_child(v)
	v.add_child(UIHelpers.clbl("❤️", 56, Color("ff6666")))
	v.add_child(UIHelpers.clbl("REPESCAGEM!", 26, UIHelpers.GOLD2))
	v.add_child(UIHelpers.clbl("Você usou sua vida extra. Não há mais segunda chance.", 12, UIHelpers.RUNE2))
	var btn := UIHelpers.gold_btn("Continuar →")
	btn.pressed.connect(_show_map); v.add_child(btn)

# ==========================================================================
#  HANDLERS DE SINAL
# ==========================================================================

func _on_beast_selected() -> void:
	_show_map()

func _on_node_chosen(target_col: int, target_lane: int) -> void:
	var node: Dictionary = GameState.enter_node(target_col, target_lane)
	match node.get("type",""):
		"partida", "elite", "boss":
			_show_match()
		"bau":
			_show_relic(func(_id): _show_map())
		"evento":
			_show_event()
		"loja":
			_show_shop()
		_:
			_show_map()

func _on_match_ended(won: bool) -> void:
	var result: String = GameState.complete_node(won)
	match result:
		"victory":
			_show_end(true)
		"defeat":
			_show_end(false)
		"repechage":
			_show_repechage()
		"act_clear":
			var current_act: int = GameState.act  # já avançou em complete_node
			_show_act_clear(current_act)
		"continue":
			var tp: String = GameState.current_node.get("type","")
			if won and tp in ["elite", "boss"]:
				_show_relic(func(_id): _show_map())
			else:
				_show_map()

func _on_event_done(needs_relic: bool) -> void:
	if needs_relic:
		_show_relic(func(_id): _show_map())
	else:
		_show_map()

func _show_shop() -> void:
	_switch_to(ShopScreen.new(), {"shop_done": _on_shop_done})

func _on_shop_done() -> void:
	_show_map()

# ==========================================================================
#  UTILITÁRIO
# ==========================================================================

func _switch_to(screen: Control, signal_map: Dictionary) -> void:
	_clear_screen()
	current_screen = screen
	add_child(screen)
	for sig_name in signal_map:
		screen.connect(sig_name, signal_map[sig_name])

func _clear_screen() -> void:
	for c in get_children():
		c.queue_free()
	current_screen = null
