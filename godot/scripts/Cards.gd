class_name Cards
## Definição das cartas + baralhos. Portado de beasts.html.
## Cada carta: mode(atk/def), type(con/fin/des/def), nm, ic, cost
## e a contribuição às 4 barras (F=Finalização, C=Controle, D=Desarme, E=Defesa).
## sta = tira fôlego do oponente · pierce = fura defesa (campo presente, ainda não ligado no motor de barras).

const ALL := {
	# --- CONTROLE (con) ---
	"passe":      {"mode":"atk","type":"con","nm":"Passe","ic":"⚽","cost":1,"C":2,"ds":"Passe curto · Controle +2"},
	"drible":     {"mode":"atk","type":"con","nm":"Drible","ic":"👟","cost":2,"C":4,"ds":"Controle de bola +4"},
	"meialua":    {"mode":"atk","type":"con","nm":"Meia-Lua","ic":"🌙","cost":1,"C":2,"F":1,"ds":"Controle +2 · Final. +1"},
	"caneta":     {"mode":"atk","type":"con","nm":"Caneta","ic":"🎩","cost":2,"C":5,"ds":"Controle de bola +5"},
	"visao":      {"mode":"atk","type":"con","nm":"Visão de Jogo","ic":"🧠","cost":1,"C":2,"F":1,"ds":"Controle +2 · Final. +1"},
	# --- FINALIZAÇÃO (fin) ---
	"cruzamento": {"mode":"atk","type":"fin","nm":"Cruzamento","ic":"📤","cost":1,"F":2,"ds":"Bola na área · Final. +2"},
	"finaliza":   {"mode":"atk","type":"fin","nm":"Finalização","ic":"🎯","cost":2,"F":4,"ds":"Chute ao gol · Final. +4"},
	"lancamento": {"mode":"atk","type":"fin","nm":"Lançamento","ic":"⚡","cost":2,"F":3,"C":1,"ds":"Final. +3 · Controle +1"},
	"colocado":   {"mode":"atk","type":"fin","nm":"Chute Colocado","ic":"🪄","cost":2,"F":3,"pierce":1,"ds":"Final. +3 · fura 1 defesa"},
	"bicuda":     {"mode":"atk","type":"fin","nm":"Bicuda","ic":"💥","cost":2,"F":5,"sta":4,"ds":"Final. +5 · tira fôlego"},
	"voleio":     {"mode":"atk","type":"fin","nm":"Voleio","ic":"🦵","cost":3,"F":7,"ds":"Final. +7 (caríssimo)"},
	"cavadinha":  {"mode":"atk","type":"fin","nm":"Cavadinha","ic":"🥄","cost":2,"F":3,"pierce":1,"ds":"Final. +3 · fura 1 defesa"},
	# --- DESARME (des) ---
	"desarme":    {"mode":"def","type":"des","nm":"Desarme","ic":"🦵","cost":1,"D":3,"ds":"Desarme +3"},
	"carrinho":   {"mode":"def","type":"des","nm":"Carrinho","ic":"🦿","cost":1,"D":2,"sta":4,"ds":"Desarme +2 · tira fôlego"},
	"botinha":    {"mode":"def","type":"des","nm":"Antecipação","ic":"🥷","cost":2,"D":4,"ds":"Desarme +4"},
	"pancada":    {"mode":"def","type":"des","nm":"Pancada","ic":"💢","cost":1,"D":1,"sta":6,"ds":"Desarme +1 · tira muito fôlego"},
	"ombro":      {"mode":"def","type":"des","nm":"Ombrada","ic":"🪨","cost":2,"D":2,"sta":6,"ds":"Desarme +2 · tira fôlego"},
	"solada":     {"mode":"def","type":"des","nm":"Solada","ic":"🦶","cost":2,"D":3,"sta":6,"ds":"Desarme +3 · tira fôlego"},
	"marcacao":   {"mode":"def","type":"des","nm":"Marcação","ic":"😖","cost":1,"D":1,"E":1,"ds":"Desarme +1 · Defesa +1"},
	# --- DEFESA (def) ---
	"defesa":     {"mode":"def","type":"def","nm":"Defesa","ic":"🛡️","cost":1,"E":3,"ds":"Defesa +3"},
	"bloqueio":   {"mode":"def","type":"def","nm":"Bloqueio","ic":"🧱","cost":1,"E":2,"ds":"Defesa +2"},
	"muralha":    {"mode":"def","type":"def","nm":"Muralha","ic":"🏰","cost":2,"E":5,"ds":"Defesa +5"},
}

# Baralhos padrão (mesma composição do beasts.html). Formato: [id, quantidade].
const ATK_SPEC := [["passe",3],["drible",2],["lancamento",2],["visao",2],["finaliza",2],["colocado",1],["bicuda",1],["pancada",3]]
const DEF_SPEC := [["defesa",3],["bloqueio",2],["desarme",3],["marcacao",2],["carrinho",2]]

static func build(spec: Array) -> Array:
	var d: Array = []
	for pair in spec:
		for i in pair[1]:
			d.append(pair[0])
	return d
