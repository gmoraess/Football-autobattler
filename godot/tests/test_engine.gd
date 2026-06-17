## Validação headless do MatchEngine — roda N partidas AI×AI e imprime estatísticas.
## Uso (da pasta godot/):
##   godot --headless --script tests/test_engine.gd
extends SceneTree

const MatchEngineScript = preload("res://scripts/MatchEngine.gd")
const CardsScript = preload("res://scripts/Cards.gd")

const N := 300

func _initialize() -> void:
	randomize()
	print("=== VALIDAÇÃO HEADLESS: %d partidas por batch ===" % N)
	print("")
	_run_batch(N, 1.0, "diff=1.0 (espelho) → esperar home ~52–58%")
	print("")
	_run_batch(N, 1.3, "diff=1.3 (elite)   → esperar home ~19%")
	print("")
	print("=== FIM ===")
	quit()

## Joga as cartas da mão do HOME com a mesma lógica de prioridade do _ai_plan() do away.
## Sempre joga a carta de maior prioridade acessível até esgotar a energia.
func _home_ai_play(eng) -> void:
	var has_ball: bool = eng.possession == "home"
	var progress := true
	while progress:
		progress = false
		var best_idx := -1
		var best_prio := -999
		for j in eng.hand.size():
			var c: Dictionary = CardsScript.ALL[eng.hand[j]]
			if c["cost"] > eng.energy:
				continue
			var p: int
			if has_ball:
				p = c.get("F", 0) * 2 + c.get("C", 0) + (1 if c.has("sta") else 0)
			else:
				p = c.get("D", 0) * 2 + c.get("E", 0) + (2 if c.has("sta") else 0)
			if p > best_prio:
				best_prio = p
				best_idx = j
		if best_idx >= 0:
			eng.play_card(best_idx)
			progress = true

func _run_batch(n: int, diff: float, label: String) -> void:
	print("--- %s ---" % label)
	var wins := {"home": 0, "away": 0}
	var total_goals := 0
	var total_turns := 0
	var total_steals := 0
	var exceptions := 0
	var reasons: Dictionary = {}

	for _i in n:
		var eng = MatchEngineScript.new()
		var pdeck: Array = CardsScript.build(CardsScript.ATK_SPEC) + CardsScript.build(CardsScript.DEF_SPEC)
		var odeck: Array = CardsScript.build(CardsScript.ATK_SPEC) + CardsScript.build(CardsScript.DEF_SPEC)
		eng.begin(
			{"name": "Home", "crest": "H", "super": "casco"},
			{"name": "Away",  "crest": "A", "super": "bicuda"},
			pdeck, odeck, diff
		)

		var safety := 0
		while not eng.over and safety < 500:
			safety += 1
			# Home usa a mesma lógica de prioridade do away (_ai_plan espelhado)
			_home_ai_play(eng)
			# Resolve turno (away joga via _ai_plan interno)
			eng.end_turn()
			for e in eng.turn_events:
				if e.get("type", "") == "steal": total_steals += 1
			if not eng.over:
				eng.start_turn()

		if safety >= 500:
			exceptions += 1
			print("  AVISO: partida %d atingiu limite de segurança (loop?)" % _i)

		total_goals += eng.score["home"] + eng.score["away"]
		# eng.turn já foi incrementado após o último turno, então -1 dá o total de turnos jogados
		total_turns += eng.turn - 1
		var w: String = eng.winner if eng.winner != "" else "none"
		wins[w] = wins.get(w, 0) + 1
		var r: String = eng.reason if eng.reason != "" else "?"
		reasons[r] = reasons.get(r, 0) + 1

	var home_w: int = wins.get("home", 0)
	var away_w: int = wins.get("away", 0)
	var none_w: int = wins.get("none", 0)
	print("  Vitórias home : %d (%.1f%%)" % [home_w, float(home_w) / float(n) * 100.0])
	print("  Vitórias away : %d (%.1f%%)" % [away_w, float(away_w) / float(n) * 100.0])
	if none_w > 0:
		print("  ERRO inconclusivos: %d" % none_w)
	print("  Média gols/partida : %.2f" % (float(total_goals) / float(n)))
	print("  Média turnos/partida: %.1f"  % (float(total_turns) / float(n)))
	print("  Roubos/partida     : %.2f" % (float(total_steals) / float(n)))
	print("  Exceções (loops)   : %d" % exceptions)
	print("  Razões de fim: %s" % str(reasons))
