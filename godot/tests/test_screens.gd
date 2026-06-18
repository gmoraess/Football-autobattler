## Smoke test de telas — instancia Main, navega seleção→mapa→partida→relíquia
## e verifica que cada _ready/render roda sem erro de runtime.
## Uso: godot --headless --path . --script tests/test_screens.gd
extends SceneTree

func _initialize() -> void:
	root.set_meta("smoke", true)
	call_deferred("_run")

func _run() -> void:
	print("=== SMOKE DE TELAS ===")
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		print("  ERRO: autoload GameState não encontrado")
		quit(); return
	print("  GameState OK")

	var MainScene: PackedScene = load("res://scenes/Main.tscn")
	var main: Control = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	print("  Main + BeastSelect: OK")

	# escolhe fera e gera a corrida
	gs.start_run("zab")
	print("  start_run('zab'): deck=%d cartas, mapa=%d atos" % [gs.deck.size(), gs.map_data.size()])

	# entra numa partida (col 0, lane 1) e abre a MatchScreen
	gs.enter_node(0, 1)
	main._show_match()
	await process_frame
	await process_frame
	var ms: Node = main.current_screen
	if ms == null:
		print("  ERRO: MatchScreen não instanciada")
		quit(); return
	print("  MatchScreen montada: %s x %s · turno %d" % [
		ms.engine.home.get("name"), ms.engine.away.get("name"), ms.engine.turn])

	# clica numa carta VIA SINAL pressed (reproduz o contexto do erro "freed while signal")
	var btns: Array = []
	_collect_buttons(ms, btns)
	var card_btn: Button = null
	for b in btns:
		if not b.disabled and b.custom_minimum_size.y > 120:  # cartas têm altura ~138
			card_btn = b; break
	if card_btn != null:
		card_btn.emit_signal("pressed")
		await process_frame
		print("  Clique de carta (sinal): OK (energia %d)" % ms.engine.energy)

	# clica FIM DE TURNO via sinal e aguarda a resolução (timer 0.8s)
	btns.clear()
	_collect_buttons(ms, btns)
	for b in btns:
		if b.text == "FIM DE TURNO":
			b.emit_signal("pressed")
			break
	for _f in 60:
		await process_frame
	print("  Fim de turno (sinal) + resolução: OK (turno %d)" % ms.engine.turn)

	# exercita a coreografia da Parte 2 (todos os caminhos: roubo, defesa, gol)
	ms.engine.busy = false
	await ms._play_turn_choreo([
		{"type": "steal", "by": "away"},
		{"type": "shot", "by": "home", "result": "save"},
		{"type": "shot", "by": "home", "result": "goal", "drain": 5, "victim": "away"},
	])
	print("  Coreografia (roubo+defesa+gol): OK (time_scale=%.1f)" % Engine.time_scale)

	# testa relíquia e evento
	main._show_relic(func(_id): pass)
	await process_frame
	print("  RelicScreen: OK")
	main._show_event()
	await process_frame
	print("  EventScreen: OK")
	main._show_shop()
	await process_frame
	print("  ShopScreen: OK (ouro %d, baralho %d)" % [gs.gold, gs.deck.size()])
	main._show_map()
	await process_frame
	print("  MapScreen: OK")

	print("=== SMOKE OK ===")
	quit()

func _collect_buttons(n: Node, out: Array) -> void:
	if n is Button:
		out.append(n)
	for ch in n.get_children():
		_collect_buttons(ch, out)
