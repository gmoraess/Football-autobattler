## Valida o parse de todos os scripts do projeto.
## Uso: godot --headless --path godot/ --script tests/test_parse.gd
extends SceneTree

func _initialize() -> void:
	print("=== VERIFICANDO PARSE DE TODOS OS SCRIPTS ===")
	var ok := true
	var scripts := [
		"res://scripts/UIHelpers.gd",
		"res://scripts/GameState.gd",
		"res://scripts/BeastSelectScreen.gd",
		"res://scripts/MapScreen.gd",
		"res://scripts/MatchScreen.gd",
		"res://scripts/RelicScreen.gd",
		"res://scripts/EventScreen.gd",
		"res://scripts/Main.gd",
		"res://scripts/Cards.gd",
		"res://scripts/MatchEngine.gd",
		"res://scripts/ShopScreen.gd",
		"res://scripts/Sfx.gd",
	]
	for path in scripts:
		var s = load(path)
		if s == null:
			print("  ERRO: falha ao carregar %s" % path)
			ok = false
		else:
			print("  OK  : %s" % path)
	print("")
	print("=== %s ===" % ("TODOS OK" if ok else "HÁ ERROS — ver acima"))
	quit()
