extends Control
## Loja (Mercado de Transferências) — comprar cartas, comprar relíquia,
## remover carta (enxugar o baralho) e ver o resumo da build.
const UIHelpers = preload("res://scripts/UIHelpers.gd")
const Cards = preload("res://scripts/Cards.gd")

signal shop_done

var offers: Array = []          # cartas à venda
var relic_offer: String = ""    # relíquia à venda ("" = nenhuma)
var remove_mode: bool = false

const TYPE_NAME := {"con": "Controle", "fin": "Finalização", "des": "Desarme", "def": "Defesa"}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offers = GameState.shop_card_offers(3)
	var avail: Array = GameState.RELICS.keys().filter(func(r): return not GameState.relics.has(r))
	avail.shuffle()
	relic_offer = avail[0] if not avail.is_empty() else ""
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	var bg := ColorRect.new()
	bg.color = UIHelpers.STONE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		root.add_theme_constant_override(s, 22)
	add_child(root)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	root.add_child(col)

	col.add_child(_header())
	if remove_mode:
		col.add_child(_remove_view())
	else:
		col.add_child(_shop_view())

func _header() -> Control:
	var pnl := UIHelpers.framed_t(14, 10)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	pnl.add_child(h)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UIHelpers.tlbl("🛒 MERCADO DE TRANSFERÊNCIAS", 22, UIHelpers.GOLD2))
	# resumo da build
	var s: Dictionary = GameState.deck_summary()
	var sum_txt := "Baralho (%d): ⚽%d  🎯%d  🦵%d  🛡%d" % [
		GameState.deck.size(), s["con"], s["fin"], s["des"], s["def"]]
	tv.add_child(UIHelpers.lbl(sum_txt, 11, UIHelpers.RUNE2))
	h.add_child(tv)
	h.add_child(UIHelpers.tlbl("🪙 %d" % GameState.gold, 22, UIHelpers.GOLD2))
	return pnl

# --- visão principal ---
func _shop_view() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)

	v.add_child(UIHelpers.clbl("CARTAS À VENDA", 12, UIHelpers.GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if offers.is_empty():
		row.add_child(UIHelpers.clbl("(esgotado)", 11, UIHelpers.RUNE2))
	for id in offers:
		row.add_child(_buy_card(id))
	v.add_child(row)

	# relíquia
	if relic_offer != "":
		v.add_child(UIHelpers.clbl("RELÍQUIA À VENDA", 12, UIHelpers.GOLD))
		var rc := CenterContainer.new()
		rc.add_child(_buy_relic(relic_offer))
		v.add_child(rc)

	# ações
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	var rm := UIHelpers.gold_btn("✂ Remover carta (−%d)" % GameState.remove_price())
	rm.disabled = GameState.gold < GameState.remove_price() or GameState.deck.size() <= 5
	rm.pressed.connect(func(): remove_mode = true; _build())
	actions.add_child(rm)
	var leave := UIHelpers.gold_btn("Sair →")
	leave.pressed.connect(func(): shop_done.emit())
	actions.add_child(leave)
	v.add_child(actions)
	return v

func _buy_card(id: String) -> Control:
	var price := GameState.card_price(id)
	var can := GameState.gold >= price
	var box := UIHelpers.framed_t(8, 6)
	box.custom_minimum_size = Vector2(160, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	v.add_child(_card_face(id))
	var btn := UIHelpers.gold_btn("Comprar  🪙%d" % price)
	btn.disabled = not can
	btn.pressed.connect(func():
		if GameState.buy_card(id):
			offers.erase(id)
			_build())
	v.add_child(btn)
	return box

func _buy_relic(id: String) -> Control:
	var data: Dictionary = GameState.RELICS[id]
	var price := GameState.relic_price()
	var box := UIHelpers.framed_t(10, 8)
	box.custom_minimum_size = Vector2(360, 0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	box.add_child(h)
	var rtex := UIHelpers.relic_tex(id)
	if rtex != null:
		var rr := UIHelpers.sprite(rtex); rr.custom_minimum_size = Vector2(44, 44)
		h.add_child(rr)
	else:
		h.add_child(UIHelpers.clbl(data["ic"], 28, Color.WHITE))
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UIHelpers.lbl(data["name"], 13, UIHelpers.GOLD2))
	var d := UIHelpers.lbl(data["desc"], 10, UIHelpers.RUNE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(d)
	h.add_child(tv)
	var btn := UIHelpers.gold_btn("🪙%d" % price)
	btn.disabled = GameState.gold < price
	btn.pressed.connect(func():
		if GameState.buy_relic(id):
			relic_offer = ""
			_build())
	h.add_child(btn)
	return box

# --- visão de remoção ---
func _remove_view() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(UIHelpers.clbl("CLIQUE NUMA CARTA PARA REMOVÊ-LA (−%d ouro)" % GameState.remove_price(), 12, UIHelpers.GOLD))
	# cartas únicas com contagem
	var counts := {}
	for id in GameState.deck:
		counts[id] = counts.get(id, 0) + 1
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for id in counts:
		grid.add_child(_remove_card(id, counts[id]))
	v.add_child(scroll)
	var back := UIHelpers.gold_btn("← Cancelar")
	back.pressed.connect(func(): remove_mode = false; _build())
	v.add_child(back)
	return v

func _remove_card(id: String, count: int) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 96)
	btn.add_theme_stylebox_override("normal",  UIHelpers.sbf(UIHelpers.PANEL_A, UIHelpers.BRONZE, 2, 9, 6, 6))
	btn.add_theme_stylebox_override("hover",   UIHelpers.sbf(UIHelpers.PANEL_A, Color("ff6a6a"), 2, 9, 6, 6))
	btn.add_theme_stylebox_override("pressed", UIHelpers.sbf(UIHelpers.PANEL_B, Color("ff6a6a"), 2, 9, 6, 6))
	btn.disabled = GameState.gold < GameState.remove_price()
	btn.pressed.connect(func():
		if GameState.remove_card(id):
			remove_mode = false
			_build())
	var face := _card_face(id, count)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIHelpers.ignore_mouse(face)
	btn.add_child(face)
	return btn

# --- "cara" de uma carta (custo + nome + tipo + descrição) ---
func _card_face(id: String, count: int = 0) -> Control:
	var c: Dictionary = Cards.ALL[id]
	var border: Color = UIHelpers.TYPE_COL.get(c["type"], UIHelpers.BRONZE)
	var pnl := PanelContainer.new()
	pnl.add_theme_stylebox_override("panel", UIHelpers.sbf(Color("17110b"), border, 2, 8, 6, 5))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pnl.add_child(v)
	var top := HBoxContainer.new()
	top.add_child(UIHelpers.clbl("⚡%d" % c["cost"], 11, UIHelpers.GOLD2))
	var nm := UIHelpers.lbl(c["nm"] + ("  ×%d" % count if count > 0 else ""), 11, UIHelpers.RUNE)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(nm)
	v.add_child(top)
	v.add_child(UIHelpers.lbl(TYPE_NAME.get(c["type"], ""), 8, border.lightened(0.25)))
	var ds := UIHelpers.lbl(c.get("ds", ""), 9, UIHelpers.RUNE2)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ds)
	return pnl
