extends RefCounted
## (sem class_name — acessado via `const MatchEngine = preload(...)`)
## Motor da partida — 4 BARRAS + ENERGIA. Lógica pura (sem UI), portada de beasts.html.

const Cards = preload("res://scripts/Cards.gd")
## Barras por personagem: F=Finalização, C=Controle, D=Desarme, E=Defesa.
## Acumulam entre turnos. F/E disparam ao encher (e zeram); C e D são comparados.

# ---- Ajustes (mesmos números validados no beasts.html) ----
const TURNS := 15
const STA_MAX := 100
const MERCY := 5
const BARFIN := 8
const BARDEF := 6
const CD_CAP := 20
const ENERGY := 3
const FMAXCAP := 99
const IMPACT_DMG := 4   # (já embutido nas cartas em Cards.gd)
const FATIGUE := 1

# ---- Estado ----
var home: Dictionary
var away: Dictionary
var diff: float = 1.0
var possession := "home"
var turn := 1
var sudden_death := false
var over := false
var busy := false
var winner := ""
var reason := ""
var score := {"home":0, "away":0}
var sta := {"home":STA_MAX, "away":STA_MAX}
var sta_max := {"home":STA_MAX, "away":STA_MAX}
var bars := {"home":{"F":0,"C":0,"D":0,"E":0}, "away":{"F":0,"C":0,"D":0,"E":0}}
var bar_max := {"home":{"F":BARFIN,"E":BARDEF}, "away":{"F":BARFIN,"E":BARDEF}}
var saves := {"home":0, "away":0}
var goal_h := false
var goal_a := false
# baralho do jogador
var deck: Array = []
var discard: Array = []
var hand: Array = []
# baralho da IA (mesma disciplina de ciclo)
var o_live: Array = []
var o_discard: Array = []
var energy := ENERGY
var energy_max := ENERGY
var o_energy := ENERGY
var enemy_plan := {"cards":[], "icon":""}
var logs: Array = []
var turn_events: Array = []   # eventos estruturados do turno (p/ coreografia da animação)
# modificadores de passiva da fera + relíquias (aplicados em begin via p_mods)
var relic_gol_drain := 0
var relic_home_roubo_fin := 0
var relic_home_roubo_ctrl := 0
var relic_impact_sta := 0
var relic_hand_size := 5

# --------------------------------------------------------------------------
func begin(p_home: Dictionary, p_away: Dictionary, p_deck: Array, p_odeck: Array, p_diff: float, p_mods: Dictionary = {}) -> void:
	home = p_home
	away = p_away
	diff = p_diff
	possession = "home"
	turn = 1
	sudden_death = false
	over = false
	busy = false
	winner = ""
	reason = ""
	score = {"home":0, "away":0}
	sta = {"home":STA_MAX, "away":STA_MAX}
	sta_max = {"home":STA_MAX, "away":STA_MAX}
	bars = {"home":{"F":0,"C":0,"D":0,"E":0}, "away":{"F":0,"C":0,"D":0,"E":0}}
	# a dificuldade do inimigo aumenta o máximo das barras do JOGADOR
	bar_max = {
		"home": {"F": roundi(BARFIN * diff), "E": roundi(BARDEF * diff)},
		"away": {"F": BARFIN, "E": BARDEF},
	}
	saves = {"home":0, "away":0}
	deck = p_deck.duplicate()
	deck.shuffle()
	discard = []
	hand = []
	o_live = p_odeck.duplicate()
	o_live.shuffle()
	o_discard = []
	energy = ENERGY
	energy_max = ENERGY
	o_energy = ENERGY
	logs = []
	# --- aplicar passiva da fera + relíquias ---
	relic_gol_drain        = p_mods.get("gol_sta_drain", 0)
	relic_home_roubo_fin   = p_mods.get("roubo_fin_bonus", 0)
	relic_home_roubo_ctrl  = p_mods.get("roubo_ctrl_bonus", 0)
	relic_impact_sta       = p_mods.get("impact_sta_bonus", 0)
	relic_hand_size        = p_mods.get("hand_size", 5)
	sta_max["home"]        = clampi(STA_MAX + p_mods.get("sta_bonus", 0), 1, 200)
	sta["home"]            = sta_max["home"]
	saves["home"]         += p_mods.get("starting_saves", 0)
	bar_max["home"]["F"]   = maxi(2, bar_max["home"]["F"] - p_mods.get("fin_bar_reduction", 0))
	bar_max["home"]["E"]   = maxi(1, bar_max["home"]["E"] - p_mods.get("def_bar_reduction", 0))
	energy_max            += p_mods.get("energy_bonus", 0)
	energy                 = energy_max
	bars["home"]["C"]      = mini(CD_CAP, p_mods.get("ctrl_bonus", 0))
	bars["home"]["F"]      = mini(FMAXCAP, p_mods.get("fin_start_bonus", 0))
	_log("🏟️ %s x %s · %d turnos" % [_nm("home"), _nm("away"), TURNS])
	start_turn()

func start_turn() -> void:
	if over: return
	busy = false
	energy = energy_max
	discard.append_array(hand)
	hand = _draw_n(relic_hand_size)
	enemy_plan = _ai_plan()

func play_card(idx: int) -> bool:
	if over or busy: return false
	if idx < 0 or idx >= hand.size(): return false
	var c: Dictionary = Cards.ALL[hand[idx]]
	if c["cost"] > energy: return false
	energy -= c["cost"]
	_apply_card("home", c)
	discard.append(hand[idx])
	hand.remove_at(idx)
	return true

## Resolve o turno (IA joga, depois roubo/chute/defesa/fôlego). NÃO compra a mão nova.
## (a flag `busy` é gerida pelo Main durante o delay de resolução)
func end_turn() -> void:
	if over: return
	for c in enemy_plan.get("cards", []):
		_apply_card("away", c)
	if enemy_plan.get("cards", []).size() > 0:
		_log("%s joga: %d carta(s)" % [_nm("away"), enemy_plan["cards"].size()])
	_resolve_turn()

# --------------------------------------------------------------------------
func _draw_n(n: int) -> Array:
	if deck.size() < n:
		discard.shuffle()
		deck.append_array(discard)
		discard.clear()
	var out: Array = []
	for i in n:
		if deck.is_empty(): break
		out.append(deck.pop_front())
	return out

func _apply_card(side: String, c: Dictionary) -> void:
	var b: Dictionary = bars[side]
	b["F"] = mini(FMAXCAP, b["F"] + c.get("F", 0))
	b["E"] = mini(FMAXCAP, b["E"] + c.get("E", 0))
	b["C"] = mini(CD_CAP, b["C"] + c.get("C", 0))
	b["D"] = mini(CD_CAP, b["D"] + c.get("D", 0))
	if c.has("sta"):
		var o := _opp(side)
		var extra: int = relic_impact_sta if side == "home" else 0
		# (C) dano de impacto reduzido ~20% pra gol ser o caminho principal (KO secundário)
		var base: int = roundi(c["sta"] * 0.8)
		sta[o] = clampi(sta[o] - (base + extra), 0, sta_max[o])

func _prio(c: Dictionary, has_ball: bool) -> int:
	if has_ball:
		return c.get("F",0) * 2 + c.get("C",0) + (1 if c.has("sta") else 0)
	return c.get("D",0) * 2 + c.get("E",0) + (2 if c.has("sta") else 0)

func _ai_plan() -> Dictionary:
	var has_ball := possession == "away"
	if o_live.size() < 5:
		o_discard.shuffle()
		o_live.append_array(o_discard)
		o_discard.clear()
	var hand_ids: Array = []
	for i in 5:
		if o_live.is_empty(): break
		hand_ids.append(o_live.pop_front())
	o_discard.append_array(hand_ids)
	var cards: Array = []
	for id in hand_ids:
		cards.append(Cards.ALL[id])
	cards.sort_custom(func(a, b): return _prio(a, has_ball) > _prio(b, has_ball))
	var e := o_energy
	var chosen: Array = []
	for c in cards:
		if c["cost"] <= e:
			e -= c["cost"]
			chosen.append(c)
	var tot := {"F":0,"C":0,"D":0,"E":0}
	for c in chosen:
		for k in ["F","C","D","E"]:
			tot[k] += c.get(k, 0)
	var best := "C"
	var bv := -1
	for k in ["F","C","D","E"]:
		if tot[k] > bv:
			bv = tot[k]
			best = k
	var will_shoot: bool = has_ball and (bars["away"]["F"] + tot["F"] >= bar_max["away"]["F"])
	var icon: String = "🥅" if will_shoot else {"F":"🎯","C":"⚽","D":"🦵","E":"🛡️"}[best]
	return {"cards": chosen, "icon": icon}

func _resolve_turn() -> void:
	goal_h = false
	goal_a = false
	turn_events = []
	# 1) ROUBO: desarme do sem-bola > controle do com-bola
	var poss := possession
	var d0 := _opp(poss)
	if bars[d0]["D"] > bars[poss]["C"]:
		possession = d0
		bars[poss]["C"] = 0
		bars[d0]["D"] = 0
		if d0 == "home":
			bars["home"]["F"] = mini(FMAXCAP, bars["home"]["F"] + relic_home_roubo_fin)
			bars["home"]["C"] = mini(CD_CAP, bars["home"]["C"] + relic_home_roubo_ctrl)
		turn_events.append({"type": "steal", "by": d0})
		_log("✋ %s ROUBOU a bola!" % _nm(d0))
	var p := possession
	var d := _opp(p)
	# 2) FINALIZAÇÃO: barra cheia -> chute (defesa guardada bloqueia)
	if bars[p]["F"] >= bar_max[p]["F"]:
		bars[p]["F"] = 0
		if saves[d] > 0:
			saves[d] -= 1
			turn_events.append({"type": "shot", "by": p, "result": "save"})
			_log("🧤 %s DEFENDEU o chute!" % _nm(d))
		else:
			score[p] += 1
			if p == "home": goal_h = true
			else: goal_a = true
			var gol_dmg: int = 3 + (relic_gol_drain if p == "home" else 0)
			sta[d] = clampi(sta[d] - gol_dmg, 0, sta_max[d])
			turn_events.append({"type": "shot", "by": p, "result": "goal", "drain": gol_dmg, "victim": d})
			_log("⚽ GOOOL de %s! %d x %d" % [_nm(p), score["home"], score["away"]])
	# 3) DEFESA: barra cheia -> guarda um chute (acumula)
	for s in ["home", "away"]:
		if bars[s]["E"] >= bar_max[s]["E"]:
			bars[s]["E"] = 0
			saves[s] += 1
	# 4) fôlego + fim
	sta["home"] = clampi(sta["home"] - FATIGUE, 0, sta_max["home"])
	sta["away"] = clampi(sta["away"] - FATIGUE, 0, sta_max["away"])
	turn += 1
	_check_end()

func _check_end() -> void:
	if sta["away"] <= 0: _finish("home", "KO"); return
	if sta["home"] <= 0: _finish("away", "KO"); return
	var dd: int = score["home"] - score["away"]
	if dd >= MERCY: _finish("home", "GOLEADA"); return
	if dd <= -MERCY: _finish("away", "GOLEADA"); return
	if sudden_death:
		if goal_h: _finish("home", "GOLDEN")
		elif goal_a: _finish("away", "GOLDEN")
		return
	if turn > TURNS:
		if score["home"] != score["away"]:
			_finish("home" if score["home"] > score["away"] else "away", "TIME")
		else:
			sudden_death = true

func _finish(w: String, r: String) -> void:
	over = true
	winner = w
	reason = r

func _opp(s: String) -> String:
	return "away" if s == "home" else "home"

func _nm(s: String) -> String:
	return (home if s == "home" else away).get("name", s)

func _log(msg: String) -> void:
	logs.append(msg)
	if logs.size() > 6:
		logs.pop_front()
