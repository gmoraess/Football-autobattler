extends Node
## Singleton autoload — estado persistente da corrida roguelike.
## Acesso: GameState.beast, GameState.deck, GameState.relics, etc.

# ==========================================================================
#  DADOS ESTÁTICOS
# ==========================================================================

const BEASTS := {
	"couraca": {
		"name": "Couraça", "crest": "🛡", "type": "Tanque",
		"super": "casco", "super_name": "Casco Imortal",
		"lore": "O tatu blindado. Muralha viva — difícil de furar, mais difícil ainda de vencer.",
		"deck_spec": [["defesa",4],["bloqueio",3],["desarme",2],["marcacao",2],["passe",2],["finaliza",2],["pancada",1]]
	},
	"gortax": {
		"name": "Górtax", "crest": "🐂", "type": "Artilheiro",
		"super": "bicuda", "super_name": "Bicuda Imortal",
		"lore": "O minotauro implacável. Uma finalização e o gol é certo.",
		"deck_spec": [["finaliza",4],["cruzamento",3],["lancamento",2],["bicuda",2],["passe",2],["defesa",1],["desarme",2]]
	},
	"aurelio": {
		"name": "Aurélio", "crest": "🦅", "type": "Maestro",
		"super": "voo", "super_name": "Voo Rasante",
		"lore": "O falcão das alturas. Controla o jogo antes de chegar à grande área.",
		"deck_spec": [["passe",3],["drible",2],["visao",2],["meialua",2],["finaliza",2],["desarme",2],["defesa",2],["bloqueio",1]]
	},
	"mandibula": {
		"name": "Mandíbula", "crest": "🐊", "type": "Impacto",
		"super": "mordida", "super_name": "Mordida Selvagem",
		"lore": "O jacaré devastador. Vence pelo fôlego — ou pela dor.",
		"deck_spec": [["carrinho",3],["pancada",3],["ombro",2],["solada",2],["desarme",2],["passe",2],["finaliza",2]]
	},
}

const RELICS := {
	"escudo_antigo":   {"name":"Escudo Antigo",    "ic":"🛡️", "desc":"Começa com 1 Defesa guardada extra."},
	"bota_craque":     {"name":"Bota de Craque",    "ic":"👟", "desc":"Barra de Finalização: máx −1."},
	"faixa_capitao":   {"name":"Faixa do Capitão",  "ic":"🎗️", "desc":"+1 carta na mão por turno."},
	"coracao_ferro":   {"name":"Coração de Ferro",  "ic":"🔥", "desc":"STA máxima +10."},
	"luvas_goleiro":   {"name":"Luvas do Goleiro",  "ic":"🧤", "desc":"Barra de Defesa: máx −1."},
	"chuteira_rapida": {"name":"Chuteira Rápida",   "ic":"⚡", "desc":"+1 energia por turno."},
	"amuleto_gol":     {"name":"Amuleto do Gol",    "ic":"⚽", "desc":"Gol drena +2 STA extra do oponente."},
	"cristal_fury":    {"name":"Cristal da Fúria",  "ic":"💎", "desc":"Super carrega 1,5× mais rápido."},
	"capa_sombria":    {"name":"Capa Sombria",      "ic":"🌑", "desc":"Começa com Controle +5 nas barras."},
	"talisma_ouro":    {"name":"Talismã de Ouro",   "ic":"🪙", "desc":"+5 Ouro ao vencer partida."},
	"sindrome_fera":   {"name":"Síndrome da Fera",  "ic":"🐾", "desc":"[Sinergia] Roubar a bola: Finalização +2."},
}

const EVENTS := [
	{
		"title": "O Oráculo do Campo",
		"text": "Uma velha feiticeira mascote oferece um 'passe mágico'. Confiar é arriscar.",
		"choices": [
			{"label": "Aceitar — ganhar Caneta", "effect": "add_card", "card": "caneta"},
			{"label": "Recusar — nada acontece", "effect": "nothing"},
		]
	},
	{
		"title": "Emboscada no Vestiário",
		"text": "Rivais sabotam seu equipamento antes do jogo.",
		"choices": [
			{"label": "Lutar! (−10 STA máx, +1 relíquia aleatória)", "effect": "sta_relic", "val": -10},
			{"label": "Recuar (−8 Ouro)",                             "effect": "gold",      "val": -8},
		]
	},
	{
		"title": "Patrocinador Misterioso",
		"text": "Um patrocinador das sombras oferece ouro sem explicar o motivo.",
		"choices": [
			{"label": "Aceitar (+15 Ouro, −5 STA máx)", "effect": "gold_sta", "gold": 15, "sta": -5},
			{"label": "Recusar — nada acontece",         "effect": "nothing"},
		]
	},
	{
		"title": "A Torcida Imortal",
		"text": "A energia da multidão é palpável. Você pode absorvê-la ou manter o foco.",
		"choices": [
			{"label": "Absorver (+1 carta Finalização)", "effect": "add_card", "card": "finaliza"},
			{"label": "Focar (+10 STA no próximo jogo)", "effect": "heal",     "val": 10},
		]
	},
	{
		"title": "Dívida de Honra",
		"text": "Um velho rival pede ajuda. Ajudar pode render aliados ou maldição.",
		"choices": [
			{"label": "Ajudar (+12 Ouro)", "effect": "gold", "val": 12},
			{"label": "Ignorar (nada)",    "effect": "nothing"},
		]
	},
]

# Decks dos inimigos
const DECK_NORMAL := [["passe",3],["drible",2],["lancamento",2],["visao",2],["finaliza",2],
                      ["colocado",1],["bicuda",1],["pancada",3],["defesa",3],["bloqueio",2],
                      ["desarme",3],["marcacao",2],["carrinho",2]]
const DECK_ELITE  := [["finaliza",3],["bicuda",2],["voleio",1],["drible",2],["lancamento",2],
                      ["passe",2],["defesa",3],["muralha",2],["desarme",3],["ombro",2],["solada",2]]
const DECK_BOSS0  := [["finaliza",3],["lancamento",3],["drible",2],["passe",2],["defesa",3],
                      ["bloqueio",2],["muralha",2],["desarme",2],["pancada",3]]
const DECK_BOSS1  := [["voleio",2],["bicuda",3],["colocado",2],["drible",2],["caneta",2],
                      ["botinha",3],["solada",2],["muralha",2],["defesa",2],["ombro",2]]
const DECK_BOSS2  := [["voleio",3],["bicuda",3],["colocado",2],["caneta",2],["finaliza",2],
                      ["muralha",3],["botinha",2],["solada",2],["defesa",2],["bloqueio",1]]

# ==========================================================================
#  ESTADO DA CORRIDA
# ==========================================================================

var beast: Dictionary = {}
var beast_id: String = ""
var deck: Array = []        # cartas da corrida (IDs)
var relics: Array = []      # relíquias ativas (IDs)
var extra_life: bool = true # repescagem disponível
var gold: int = 20

# posição no mapa
var act: int = 0            # ato atual (0..2)
var col: int = -1           # coluna atual (-1 = antes de entrar no ato)
var lane: int = 1           # raia atual (0, 1, 2)

# dados do mapa
var map_data: Array = []    # [ato0, ato1, ato2], cada ato = [col0, col1, col2, col_boss]
var current_node: Dictionary = {}

# bônus temporário de STA (de eventos)
var sta_bonus: int = 0

# ==========================================================================
#  INÍCIO DA CORRIDA
# ==========================================================================

func start_run(p_beast_id: String) -> void:
	beast_id = p_beast_id
	beast = BEASTS[p_beast_id].duplicate(true)
	deck = _build_deck(beast["deck_spec"])
	relics = []
	extra_life = true
	gold = 20
	act = 0; col = -1; lane = 1
	sta_bonus = 0
	generate_map()

func _build_deck(spec: Array) -> Array:
	var d: Array = []
	for pair in spec:
		for _i in pair[1]:
			d.append(pair[0])
	return d

# ==========================================================================
#  GERAÇÃO DO MAPA
# ==========================================================================

func generate_map() -> void:
	map_data = []
	for a in 3:
		var base_diff: float = 0.80 + a * 0.25
		var act_cols: Array = []

		# Col 0 — 3 partidas de entrada
		var c0: Array = []
		for _l in 3:
			c0.append(_mk_node("partida", base_diff, a, false))
		act_cols.append(c0)

		# Col 1 — mix aleatório por variante
		var variants := [
			["partida", "evento", "loja"],
			["evento",  "partida","partida"],
			["loja",    "partida","evento"],
		]
		var picked: Array = variants[randi() % variants.size()]
		var c1: Array = []
		for l in 3:
			var tp: String = picked[l]
			c1.append(_mk_node(tp, base_diff + 0.05, a, false))
		act_cols.append(c1)

		# Col 2 — elite/bau/elite (bau garantido no centro)
		act_cols.append([
			_mk_node("elite", base_diff + 0.12, a, true),
			_mk_node("bau",   base_diff + 0.12, a, false),
			_mk_node("elite", base_diff + 0.12, a, true),
		])

		# Col 3 — boss (único nó)
		act_cols.append([_mk_boss(a, base_diff + 0.40)])

		map_data.append(act_cols)

func _mk_node(tp: String, diff: float, a: int, elite: bool) -> Dictionary:
	var enemy: Dictionary = {}
	if tp in ["partida", "elite"]:
		enemy = _random_enemy(a, elite)
	return {"type": tp, "diff": diff, "enemy": enemy, "visited": false, "deck_key": "elite" if elite else "normal"}

func _mk_boss(a: int, diff: float) -> Dictionary:
	var bosses := [
		{"name":"Mantis da Tempestade", "crest":"🦗", "super":"voo",    "deck_key":"boss0"},
		{"name":"Leão Dourado",          "crest":"🦁", "super":"casco",  "deck_key":"boss1"},
		{"name":"Quetzal, a Serpente Imortal", "crest":"🐉", "super":"bicuda", "deck_key":"boss2"},
	]
	var e: Dictionary = bosses[a].duplicate()
	return {"type":"boss", "diff": diff, "enemy": e, "visited": false, "deck_key": e["deck_key"]}

func _random_enemy(a: int, elite: bool) -> Dictionary:
	var pools := [
		[{"name":"Rinoceronte Sombrio","crest":"🦏","super":""},
		 {"name":"Lobo da Névoa",       "crest":"🐺","super":""},
		 {"name":"Urso do Norte",       "crest":"🐻","super":""}],
		[{"name":"Escorpião Ferreiro",  "crest":"🦂","super":"bicuda"},
		 {"name":"Tigre Relâmpago",     "crest":"🐯","super":"voo"},
		 {"name":"Gorila das Sombras",  "crest":"🦍","super":"casco"}],
		[{"name":"Dragão de Jade",      "crest":"🐲","super":"bicuda"},
		 {"name":"Serpente Estelar",    "crest":"🐍","super":"mordida"},
		 {"name":"Fênix das Cinzas",    "crest":"🔥","super":"voo"}],
	]
	var e: Dictionary = pools[a][randi() % pools[a].size()].duplicate()
	if elite:
		e["name"] = "Elite — " + e["name"]
	return e

func enemy_deck(deck_key: String) -> Array:
	var specs := {"normal":DECK_NORMAL, "elite":DECK_ELITE,
	              "boss0":DECK_BOSS0,   "boss1":DECK_BOSS1, "boss2":DECK_BOSS2}
	var spec: Array = specs.get(deck_key, DECK_NORMAL)
	return _build_deck(spec)

# ==========================================================================
#  NAVEGAÇÃO
# ==========================================================================

## Raias acessíveis na próxima coluna a partir de (col, lane).
## Retorna Array de [target_col, target_lane].
func reachable_next() -> Array:
	var next_col: int = col + 1
	if next_col >= map_data[act].size():
		return []
	# boss (1 único nó)
	if map_data[act][next_col].size() == 1:
		return [[next_col, 0]]
	# colunas normais
	var result: Array = []
	for l in 3:
		if col == -1 or abs(l - lane) <= 1:
			result.append([next_col, l])
	return result

## Entra num nó. Atualiza posição e marca como visitado.
func enter_node(target_col: int, target_lane: int) -> Dictionary:
	col = target_col
	lane = target_lane
	var node: Dictionary
	if map_data[act][col].size() == 1:
		node = map_data[act][col][0]
	else:
		node = map_data[act][col][lane]
	node["visited"] = true
	current_node = node
	return node

## Chamado após o fim de uma partida (ou nó sem luta). Retorna o que fazer a seguir.
## Resultado: "continue" | "defeat" | "repechage" | "act_clear" | "victory"
func complete_node(won: bool) -> String:
	var tp: String = current_node.get("type", "partida")
	if not won:
		if tp in ["partida"] and extra_life:
			extra_life = false
			return "repechage"
		return "defeat"
	# ganhou — recompensa de ouro
	match tp:
		"partida": gold += 10
		"elite":   gold += 20
		"boss":    gold += 30
	if tp == "boss":
		act += 1; col = -1; lane = 1
		if act >= 3:
			return "victory"
		return "act_clear"
	return "continue"

# ==========================================================================
#  RELÍQUIAS
# ==========================================================================

func add_relic(relic_id: String) -> void:
	if not relics.has(relic_id):
		relics.append(relic_id)

func random_relic_choices(n: int = 3) -> Array:
	var available: Array = RELICS.keys().filter(func(r): return not relics.has(r))
	available.shuffle()
	return available.slice(0, mini(n, available.size()))

func get_relic_mods() -> Dictionary:
	var m := {
		"sta_bonus": sta_bonus, "starting_saves": 0,
		"fin_bar_reduction": 0, "def_bar_reduction": 0,
		"energy_bonus": 0, "hand_size": 5,
		"gol_sta_drain": 0, "fury_gain_mult": 1.0,
		"ctrl_bonus": 0, "roubo_fin_bonus": 0,
	}
	for r in relics:
		match r:
			"escudo_antigo":   m["starting_saves"] += 1
			"bota_craque":     m["fin_bar_reduction"] += 1
			"faixa_capitao":   m["hand_size"] += 1
			"coracao_ferro":   m["sta_bonus"] += 10
			"luvas_goleiro":   m["def_bar_reduction"] += 1
			"chuteira_rapida": m["energy_bonus"] += 1
			"amuleto_gol":     m["gol_sta_drain"] += 2
			"cristal_fury":    m["fury_gain_mult"] *= 1.5
			"capa_sombria":    m["ctrl_bonus"] += 5
			"sindrome_fera":   m["roubo_fin_bonus"] += 2
	sta_bonus = 0  # consome o bônus de STA de evento após repassar
	return m

# ==========================================================================
#  BARALHO
# ==========================================================================

func add_card(card_id: String) -> void:
	deck.append(card_id)
