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

## 2. A MÁQUINA DE SLOT (proposta concreta para a v1)

A ideia: o slot é o **resolvedor de aleatoriedade**, e os **símbolos dos reels são a "build/deck"** do jogador (é aqui que mora a estratégia na Parte 2).

### 2.1 Símbolos
**Reels de ATAQUE:** ⚽ Gol · 🎯 Mira (chute de poder) · 👟 Drible (mantém posse) · 🔁 Passe (posse segura) · ⭕ Erro (trave/fora) · 💥 Impacto (bola fere o adversário → dano STA).

**Reels de DEFESA:** 🧤 Defesa · ✋ Desarme (rouba) · 🧱 Bloqueio · 😖 Pressão (força erro) · 💥 Pancada (bloqueio de corpo → dano STA) · ⚠️ Vacilo (falha).

### 2.2 Resolução (legível e divertida)
- Gira **3 reels** → lê a **linha**:
  - **3 iguais** = efeito máximo (ex.: ⚽⚽⚽ = gol certo; 🧤🧤🧤 = defesa perfeita + recupera STA).
  - **2 iguais** = efeito parcial, **contestado** por uma rolagem oculta (stats + STA do oponente).
  - **3 diferentes** = resultado fraco (geralmente perde posse / chute pra fora).
- **💥 em qualquer reel** = dano de STA extra (acumula com a quantidade de 💥).

### 2.3 A AÇÃO escolhida enviesa os reels
- Ataque: **Finalizar** (+⚽/🎯, mas +⭕ risco) · **Driblar** (+👟) · **Tocar** (+🔁 seguro).
- Defesa: **Desarmar** (+✋, +⚠️ risco) · **Defender** (+🧤/🧱) · **Pressionar** (+😖/💥).

### 2.4 Onde entram as builds (Parte 2)
- Na loja você **compra/forja símbolos** para colocar nos seus reels (deck-building no slot).
- **Relíquias** alteram regras de payline (ex.: "💥 vira coringa", "⚽ paga com 2 também").
- **Build de 💥/STA** = vencer por nocaute de fôlego → realiza a sua ideia de "estratégia válida".

---

## 3. Premissas que travei (me corrija se algo estiver diferente)

1. "9 turnos (10 min)" = **9 turnos**, cada um ~10 min de jogo (90 min no total).
2. STA = **barra de vida** do time; zerá-la = **derrota imediata** (nocaute).
3. Cada turno é **uma disputa de posse**; o modo (ataque/defesa) segue quem tem a bola.
4. A **decisão do jogador** é **escolher a ação** (que enviesa o slot); o **slot resolve** a sorte.
5. Vamos com a **máquina de slot primeiro**; dado/carta ficam como arquitetura futura plugável.
6. Mantemos o esqueleto roguelike (Copa + loja), mas adaptado ao slot — **na Parte 2**.

---

## 4. PARTE 1 — Núcleo da partida + Máquina de Slot ✅ ENTREGUE (`beasts.html`)

**Objetivo:** provar que o duelo por turnos com slot é divertido. Sandbox de 1 partida (Couraça, o Tatu vs Górtax, o Minotauro), isolado e rápido de testar.

1. ✅ **Rebrand:** "World Cup Beasts"; protagonista fera-tatu (sprite pixel desenhado em canvas); arquivo novo `beasts.html` (o jogo de física antigo segue intacto como referência).
2. ✅ **Tela de partida turn-based:** 2 barras de **STA/vida**, placar, **contador de turno (1/9)**, indicador de **posse**, painel da **máquina de slot**.
3. ✅ **Loop de turnos:** posse define ataque/defesa + **pausa com câmera slow-mo** no início de cada turno.
4. ✅ **Máquina de slot:** 3 reels animados (parada escalonada), pools de símbolos por modo, **3 ações por modo** que enviesam os pesos.
5. ✅ **Resolução:** combinações → resultados (gol/erro/mantém/perde posse; defesa/roubo/bloqueio/força-erro) + **dano de STA por 💥** + contestação por stats/STA.
6. ✅ **3 regras de vitória:** placar nos 9 turnos (empate → morte súbita), goleada de 5 gols, e nocaute por STA (vale na morte súbita).
7. ✅ **Mecânica STA:** dano por turno (cansaço) + dano por 💥 + **nocaute**.
8. ✅ **VFX:** slow-mo, animação dos reels, shake/partículas no gol e no impacto, sprites pixel (tatu/minotauro) e bola com runa de alvo.
9. ✅ **Teste headless:** 24.000 partidas, **0 exceções**. Balanceamento: foco em gol **49%** vs foco em impacto **50%** (co-equivalentes, ninguém domina), aleatório **29%** (a estratégia quase dobra a vitória); nocaute é via de vitória real (~45% das vitórias por impacto).

**Status:** jogável em `beasts.html`. **Falta validar com o usuário** se o slot "gruda" antes da Parte 2.

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
