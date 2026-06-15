# 🛡️⚽ World Cup Beasts — Roadmap de Redesign

> Redesign grande: de **autobattler de física em tempo real** para um **duelo de futebol por turnos resolvido por MÁQUINA DE SLOT**, num mundo estilo Yu-Gi-Oh onde tudo se decide em uma partida de futebol.
>
> Dividido em **2 partes** porque são mudanças grandes. **Parte 1 = provar a mecânica do slot.** **Parte 2 = mundo, mascotes, builds e integração no roguelike completo.**

---

## 0. Visão (o "elevator pitch")

**World Cup Beasts.** Num mundo onde nações de feras resolvem tudo — guerras, tronos, honra — em **embates de futebol** (lógica Yu-Gi-Oh: "o duelo decide"), você é a **fera-tatu blindada**, um campeão convocado para a Copa. Cada partida é um **duelo por turnos**: você escolhe uma ação e gira a **máquina de slot**, que decide o destino do lance. Stamina é vida: a bola é uma arma e quem fica sem fôlego cai.

- **Direção de arte:** pixel art (imagens 3/4), arena gótica sombria de "duelistas".
- **Protagonista:** fera-tatu blindada das imagens 1–4.
- **Adversários:** mascotes de Copa do Mundo reimaginados como feras.

---

## 1. Modelo unificado da PARTIDA (as regras, organizadas)

### 1.1 Estrutura de tempo
- A partida tem **9 turnos** (cada turno representa ~10 min → 90 min de jogo).
- A partida **termina antecipadamente** se a barra de **STA (stamina = vida)** de um time **zerar**.

### 1.2 Posse define o "modo" do turno
Só um time tem a bola por vez, então cada turno é uma **disputa de posse**:
- **Modo ATAQUE** (você tem a bola): ações sobre finalizar / driblar / tocar.
- **Modo DEFESA** (o adversário tem a bola): ações sobre roubar / defender / pressionar.
- O resultado do turno pode **manter ou virar a posse** → isso decide o modo do próximo turno.

### 1.3 O turno, passo a passo
1. **Pausa dramática** com câmera em **slow-motion** (efeito especial) — destaca o momento.
2. **Você escolhe uma AÇÃO** (a ação enviesa os pesos dos reels — é a camada de decisão).
3. **GIRA a máquina de slot** (3 reels animados).
4. A **combinação** (payline) → **resultado**, contestado por stats/STA do oponente.
5. **Aplica o resultado**: placar, posse, STA (incluindo dano de bola) + VFX.
6. Próximo turno. Após 9 turnos **ou** STA zerada → fim.

### 1.4 Resultados possíveis (o que o slot decide)
- **Com a bola (ataque):** marcar **GOL** · **errar** (trave / pra fora / defesa) · **manter posse** · **perder posse**.
- **Sem a bola (defesa):** **roubar a bola** · **defender o chute** · **forçar o erro do adversário** · (falhar → sofrer).
- **Transversal:** se a bola **bate em um jogador**, ele **perde STA** — e isso pode ser o foco de uma build (vencer por nocaute de stamina em vez de gols).

### 1.5 Condições de vitória (3 formas — confirmadas)
- **STA é uma segunda barra de vida.** Cai um pouco por turno (cansaço) **e** quando a bola acerta o jogador (💥).
- **1) Placar:** ao fim dos **9 turnos**, vence quem tem **mais gols**.
  - Empate → **MORTE SÚBITA**: estende **1 turno por vez**; o **primeiro a marcar** vence.
- **2) Goleada:** **5 gols de diferença** a qualquer momento = vitória imediata.
- **3) Nocaute:** **zerar a STA** do adversário = vitória imediata — **vale inclusive na morte súbita**.

---

## 2. O RESOLVEDOR: CARTAS  ⚠️ (slot descartado — pivot para cartas)

> O slot foi testado e descartado pelo usuário. O resolvedor de aleatoriedade agora são **CARTAS**, num duelo simétrico (ambos os lados jogam cartas; a IA joga o adversário). É aqui que mora a "build/deck" na Parte 2.

### 2.1 Regras de jogada (definidas pelo usuário)
- A cada turno você monta uma **jogada** com a mão sorteada.
- **Máx. 1 carta de FINALIZAÇÃO por turno** (não faz sentido marcar 2 gols no mesmo lance).
- **O resto empilha** (pode jogar vários do mesmo tipo), salvo regra própria da carta.
- **Teto de 3 cartas por jogada** (anti-spam; ainda permite empilhar 2-3).
- A jogada é **animada no campo** (bola + personagens se movendo).

### 2.2 Cartas (v1)
**Ataque:** 🅿️ Tabela · 👟 Drible · ⚡ Lançamento · 🧠 Visão de Jogo (apoio) · ⚽ Finalização · 🪄 Chute Colocado · 💥 Bicuda (finalização) · 💢 Pancada (impacto/STA).
**Defesa:** 🧤 Defesa · 🧱 Bloqueio (block) · ✋ Desarme (rouba) · 😖 Marcação (pressão) · 💢 Carrinho (impacto/STA).

### 2.3 Resolução DETERMINÍSTICA + ZONAS de campo (sem sorte na resolução)
- **Nada de dado na resolução:** tudo é **valor vs alvo** / **valor seu vs valor do rival**. A variância vem só do **sorteio das cartas** → builds funcionam de forma fiável.
- **Campo em 4 zonas:** Defesa/Meio de cada lado. Só dá pra **FINALIZAR** na **Zona de Ataque** do rival → é preciso avançar antes.
- **Avanço:** seu valor de avanço ≥ alvo fixo → sobe de zona (não é barrado pela guarda; a defesa para via roubo).
- **Roubo (X vs X):** desarme do defensor vs **controle** do atacante. Avançar agressivo (rápido) expõe a bola; avançar seguro (passe) mantém a posse, mais devagar.
- **Gol:** chute (potência+precisão+embalo) ≥ **guarda do goleiro** (blocks + DEF). Atingiu o alvo, é gol.
- **Impacto (💥):** dano de STA determinístico; **só conecta se o lance vingou** (roubo/erro anulam) — esse é o contrajogo.
- **Turnos:** **15** (recomendado por simulação — ver §4). Mais que os 9 originais por causa das zonas.

### 2.4 Onde entram as builds (Parte 2)
- Na loja você **compra/forja cartas** para o seu baralho (deck-building).
- **Cartas/relíquias com regra própria** mudam o jogo (coringas, combos).
- **Build de 💥/STA** = vencer por **nocaute de fôlego** → realiza a sua ideia de "estratégia válida" (validada: ~28% das vitórias do deck de impacto são por KO).

---

## 3. Premissas que travei (me corrija se algo estiver diferente)

1. "9 turnos (10 min)" = **9 turnos**, cada um ~10 min de jogo (90 min no total).
2. STA = **barra de vida** do time; zerá-la = **derrota imediata** (nocaute).
3. Cada turno é **uma disputa de posse**; o modo (ataque/defesa) segue quem tem a bola.
4. A **decisão do jogador** é **escolher a ação** (que enviesa o slot); o **slot resolve** a sorte.
5. ~~Máquina de slot~~ → **descartada**. Resolvedor agora é **CARTAS** (duelo simétrico, IA joga o adversário). Dado fica como arquitetura futura plugável.
6. Mantemos o esqueleto roguelike (Copa + loja), mas adaptado ao slot — **na Parte 2**.

---

## 4. PARTE 1 — Duelo de Cartas com campo animado ✅ ENTREGUE (`beasts.html`)

**Objetivo:** provar que o duelo por turnos com **cartas** é divertido. Sandbox de 1 partida (Couraça, o Tatu vs Górtax, o Minotauro), isolado e rápido de testar.

1. ✅ **Rebrand:** "World Cup Beasts"; protagonista fera-tatu (sprite pixel em canvas); arquivo `beasts.html` (o jogo de física antigo segue como referência).
2. ✅ **Tela turn-based:** 2 barras de **STA/vida**, placar, **turno (1/9)**, indicador de **posse**, **mão de cartas** + **zona de jogada**.
3. ✅ **Sistema de cartas DETERMINÍSTICO:** sem sorte na resolução (valor vs alvo / X vs X). Regras "1 finalização + resto empilha, teto de 3"; **embalo (momentum)**.
4. ✅ **Campo em 4 ZONAS:** avanço por alvo fixo, roubo = controle vs desarme, finalização só na Zona de Ataque, gol = chute vs guarda do goleiro.
5. ✅ **Resolução simétrica:** a **IA joga as cartas do Górtax** (ciente da zona: desarma no meio, guarda na área).
6. ✅ **Campo de futebol 5v5 animado:** 10 jogadores com formação; **campo normal** (orientação de zona só na barra de cima). Movimento com **revezamento**: atacando, os companheiros acompanham; defendendo, a equipe forma **linha que recua** (sensação de "o rival avança na minha defesa") e só **UM zagueiro dá o bote** no momento do desarme (sem ficar colado/"lutando"). Se o bote falha, o atacante **se esquiva** e avança. A **finalização é um CHUTE de verdade**: a bola vai **sozinha em câmera lenta** até o gol (o batedor não entra na rede) e o goleiro **defende** ou ela **entra** — com zoom + fogo + rede balançando. Cartas com valores claros e log narrado como futebol.
7. ✅ **3 regras de vitória:** placar (empate → morte súbita), goleada de 5 gols, e nocaute por STA (vale na morte súbita).
8. ✅ **Turnos = 15** (recomendado por varredura de simulação).
9. ✅ **Teste headless:** 48.000 partidas, **0 exceções**. Placar médio ~1,1×1,1 (≈3,4 chutes/jogo). Decisão: **placar 65% · gol-de-ouro 18% · nocaute 17%**. Estratégias: **gol 50%**, **impacto 37%** (build secundária viável; ~23% por nocaute), **aleatório 12%** → a estratégia vale ~4× a sorte. *(Impacto co-equalizável na Parte 2 com cartas/relíquias dedicadas.)*

**Status:** jogável em `beasts.html`. **Falta validar com o usuário** se o duelo de cartas (determinístico + zonas) "gruda" antes da Parte 2.

---

## 5. PARTE 2 — Mundo, Mascotes, Builds e Integração

**Objetivo:** transformar o protótipo num jogo completo com identidade e profundidade.

1. **Lore estilo Yu-Gi-Oh:** mundo onde tudo se decide em duelos de futebol (texto no jogo + README); facções = **nações-fera**.
2. **Mascotes remodelados:** protagonista (Tatu) + **roster de adversários** (mascotes de Copa reimaginados como feras), cada um com identidade e **viés de símbolos** no slot.
3. **Deck-building no slot:** comprar/forjar símbolos para os reels na loja; **relíquias** que mudam regras de payline; **builds** (gol / controle de posse / 💥-STA).
4. **Reintegração no loop de Copa:** bracket (Grupos → Final) e loja entre rodadas, agora girando em torno do slot/deck.
5. **Chefe final:** uma **fera lendária** com reels/regra única.
6. **Polish:** balanceamento por mascote, VFX por fera, **áudio** (impacto pede som), arte pixel.
7. **Arquitetura plugável** para os futuros **3 personagens** (slot / dado / carta) — uma interface comum de "resolvedor de aleatoriedade", deixando a porta aberta sem comprometer agora.

**Entregável da Parte 2:** o jogo roguelike completo, com mundo, mascotes e builds em volta da máquina de slot.

---

## 6. Perguntas em aberto (para refinar quando você quiser)
- Vitória por STA: **nocaute imediato** ou só **critério de desempate**?
- A escolha de ação por turno deve ser **1 ação** ou um **mini-loadout** (ex.: gastar energia em mais de uma)?
- Quantos adversários no campo importam para o dano de 💥, ou abstraímos como "time" (uma barra de STA)?
