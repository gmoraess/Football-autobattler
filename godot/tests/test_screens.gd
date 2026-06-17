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

	# joga um turno inteiro
	for i in ms.engine.hand.size():
		ms.engine.play_card(0)
	ms.render()
	await process_frame
	print("  Jogou cartas + render: OK (energia %d)" % ms.engine.energy)

	# testa relíquia e evento
	main._show_relic(func(_id): pass)
	await process_frame
	print("  RelicScreen: OK")
	main._show_event()
	await process_frame
	print("  EventScreen: OK")
	main._show_map()
	await process_frame
	print("  MapScreen: OK")

	print("=== SMOKE OK ===")
	quit()
