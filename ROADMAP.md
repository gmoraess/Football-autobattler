# 🛡️⚽ World Cup Beasts — Roadmap de Redesign

> Redesign grande: de **autobattler de física em tempo real** para um **duelo de futebol por turnos resolvido por MÁQUINA DE SLOT**, num mundo estilo Yu-Gi-Oh onde tudo se decide em uma partida de futebol.
>
> Dividido em **2 partes** porque são mudanças grandes. **Parte 1 = provar a mecânica do slot.** **Parte 2 = mundo, mascotes, builds e integração no roguelike completo.**

> ### 📍 ESTADO ATUAL (jun/2026)
> O slot foi **descartado** (resolvedor = **cartas**), e o jogo foi **portado do `beasts.html` para Godot 4** (pasta `godot/`). Tudo que era "Parte 2/2+" (4 feras, mapa roguelike de 3 atos, relíquias, eventos, loja, super lance, repescagem) **já está jogável no port**. A frente de trabalho atual é a **Parte 3 — arte pintada idêntica ao mock** (ver §7). O `beasts.html` e o `index.html` ficam como **legado/referência**.

---

## ⭐ REDESIGN ATUAL — Mecânica das 4 BARRAS (substitui o slot e as fases)

> As seções abaixo (slot machine, fases de ataque/defesa, 9 turnos, divisão do campo em 4 zonas) ficam como **histórico**. O modelo vigente é o de **4 barras acumulativas por personagem**, descrito aqui. Dividido em 2 partes:
> **Parte 1 (FEITA) = motor + HUD funcional.** **Parte 2 = fidelidade visual pixel-art ao mock (arena gótica, retratos, molduras).**

### As 4 barras (por personagem, acumulam entre turnos)
1. **🎯 Finalização** — quando **enche, chuta ao gol**. O máximo escala com a **dificuldade do inimigo** (inimigo fácil enche rápido, ex. 0/7; elite/chefe exige bem mais). Zera ao disparar.
2. **⚽ Controle de bola** — precisa **permanecer maior que o Desarme do oponente**, senão você **perde a bola** (e não finaliza mesmo com a barra de finalização cheia).
3. **🦵 Desarme** — precisa ser **maior que o Controle do inimigo** para **roubar** a posse (empate = não rouba; estritamente maior).
4. **🛡️ Defesa** — quando **enche, guarda uma defesa** que bloqueia o próximo chute. **Acumula** (encher 2× = 2 chutes defendidos).

### Posse de bola (sem mais "fases")
- Não há mais fase de ataque/defesa nem divisão do campo em zonas. Apenas um marcador **"⚽ POSSE DE BOLA"** acima de quem tem a bola.
- **Com a bola:** destacam **Finalização + Controle**. **Sem a bola:** destacam **Desarme + Defesa**.

### Energia + cartas
- **3 de energia por turno.** Cada carta tem **custo** e enche barras (ex.: Passe ⚽+2 custo 1; Finalização 🎯+4 custo 2; Carrinho 🦵+2 custo 1 + tira fôlego; Defesa 🛡️+3 custo 1).
- Cartas de impacto (`sta`) drenam o **fôlego** do oponente (fôlego = vida; zerou = KO).

### Intenção do inimigo (estilo Slay the Spire)
- Mostrada **só por ícone acima da cabeça do adversário** (🎯/⚽/🦵/🛡️, ou 🥅 quando o chute é iminente). Sem números.

### Resolução do turno (ordem)
1. **Roubo:** se `Desarme(sem-bola) > Controle(com-bola)` → vira a posse (zera os dois).
2. **Finalização:** se a barra do possuidor encheu → chute; se o defensor tem defesa guardada, bloqueia; senão **GOL** (zera a barra).
3. **Defesa:** cada lado com a barra cheia ganha **+1 defesa guardada** (zera a barra).
4. **Fôlego** cai (fadiga); fim por **KO**, **goleada (≥5)**, **placar no tempo** ou **morte súbita**.

### Balanceamento (validação headless, 300–400 partidas, diff=1)
- **0 exceções**; **~1,9 gol/partida**; **~18 turnos** de média; vitória do jogador **~52–58%** no espelho (decidida por gols, não só por KO).
- Knob de dificuldade testado: diff 1.0 ≈ 58% · 1.3 ≈ 19% · 1.6 ≈ 4% (barra do jogador cresce com a dificuldade do inimigo). Curva da campanha suavizada: partida ato I `diff 0.80`, elite `+0.12`, chefe final `≈1.32`.

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

## 5. PARTE 2 — Campanha da Copa + Deck-building ✅ ENTREGUE (`beasts.html`)

1. ✅ **Lore Yu-Gi-Oh:** tela-título com o mundo onde tudo se decide num embate de futebol (Copa dos Mil Anos).
2. ✅ **Mascotes-fera selecionáveis (4):** 🛡️ Couraça (tatu, muralha), 🐂 Górtax (minotauro, artilheiro), 🦅 Aurélio (falcão, maestro/controle), 🐊 Mandíbula (jacaré, impacto). Cada fera = stats + baralho (sprite genérico por crista).
3. ✅ **Deck-building (loja):** entre as fases, compra de cartas (vão p/ Ataque ou Defesa) e "enxugar o baralho" (remover carta); 8 cartas novas de loja (Meia-Lua, Caneta, Cavadinha, Voleio, Ombrada, Muralha, Antecipação, Solada).
4. ✅ **Chaveamento da Copa:** Grupos (3, **perdoáveis** — derrota não elimina) → Oitavas → Quartas → Semi → **Final** (mata-mata elimina). Oponentes escalados por fase + premium nos tiers altos.
5. ✅ **Chefe final:** 🐉 **Quetzal, a Serpente Imortal** (baralho lendário: Voleio, Muralha, Caneta…).
6. ✅ **Telas:** título, seleção de fera, hub com bracket + prévia do oponente + resumo do baralho, loja, resultado de fase (vitória/derrota-nos-grupos/eliminado), campeão, partida avulsa (treino).
7. ✅ **Balanceamento (sim. headless):** **campeão por fera 15% / 15% / 18% / 21%** (paridade), e **9-11% sem usar a loja** (deck-building tem valor). Duelo base segue equilibrado (gol 57% vs impacto 59%). **0 exceções** em campanha + render.

**Pendências de polimento (futuro):** sprites únicos por fera (hoje é disco+emoji), áudio, mais cartas/relíquias, e a arquitetura plugável p/ os 3 resolvedores (carta já é o oficial; dado/slot ficam como extensão).

## 5b. PARTE 2+ — Mapa roguelike (3 atos) + Relíquias + Super + Intenção ✅ ENTREGUE
Após pesquisa do gênero (Slay the Spire, Monster Train, Balatro / futebol arcade Captain Tsubasa, Inazuma), adicionado:
1. ✅ **Clareza:** cores fixas por LADO (casa azul · visitante laranja, fera = crista); **intenção do inimigo** telegrafada (jogada travada no início do turno); **medidor de resultado** exato ao montar a jogada (resolução determinística → estilo Into the Breach).
2. ✅ **Mapa randômico de 3 ATOS** (estilo StS): gerado toda vez, **3 trilhas** com bifurcações sobe/desce; nós de ⚽ partida · 💀 elite · ❓ evento · 🎁 baú de relíquia (garantido no meio) · 🛒 loja · 👑 final do ato. Caminho curto (~3 partidas/ato).
3. ✅ **Relíquias** (11, com 2 de **sinergia**) — modificadores passivos da corrida (baú, elite, evento). Tela de escolha (1 de 3).
4. ✅ **Super Lance por fera** (Fúria que carrega): Casco Imortal (tatu) · Bicuda Imortal (mino) · Voo Rasante (falcão) · Mordida Selvagem (jacaré). Barra + botão; o medidor mostra o efeito.
5. ✅ **Eventos** (escolhas narrativas com risco/recompensa).
6. ✅ **Vida extra (❤️ repescagem):** 1 por corrida — salva 1 derrota fora do mata-mata; o que torna a gauntlet de 3 atos justa.
7. ✅ **Balanceamento (sim. headless):** campeão **21/21/21/22%** por fera (parelho); deck comum mantém paridade; relíquias/super buffam o jogador, vida extra equilibra a duração. **0 exceções** em ~60k campanhas + smoke de todas as telas/fluxo.

---

## 5c. PARTE 3 — Port para Godot 4 + Arte pintada 🔄 EM ANDAMENTO

Saída do `beasts.html` (web) para um projeto **Godot 4** (`godot/`), com a campanha inteira recriada por cima de um motor puro e testável.

1. ✅ **Motor portado:** `MatchEngine.gd` — lógica pura das 4 barras, sem UI, determinística. Validado headless (`tests/test_engine.gd`): **0 exceções** em 300 partidas IA×IA, ~55% de vitória do jogador no espelho (`diff=1.0`).
2. ✅ **Campanha recriada em Godot:** `GameState.gd` (autoload) com 4 feras, 11 relíquias, 5 eventos e gerador de mapa de 3 atos; telas `BeastSelect / Map / Match / Relic / Event` roteadas por sinais em `Main.gd`. Relíquias entram no motor via `p_mods` (Dicionário), mantendo o motor puro.
3. ✅ **Estrutura sem `.tscn` manual:** UI montada por código (`UIHelpers.gd` centraliza cores e widgets). Parse de todos os scripts verificado (`tests/test_parse.gd`).
4. 🔄 **Arte idêntica ao mock (Parte 3 atual):** substituir o procedural (StyleBox + emoji) por **arte pintada gótica** — fundo de arena, feras/inimigos/chefes, ilustrações de carta, ícones e molduras. Manifesto completo de PNGs em **`godot/assets/ASSETS.md`**; fontes (Cinzel/Oswald/Barlow) já incluídas; layout da partida sendo reconstruído pra bater pixel-a-pixel com a referência.
5. ⏳ **Pendências:** loja completa (hoje é stub que dá ouro + carta), efeito do Talismã de Ouro no `complete_node()`, e integração dos assets conforme chegam.

---

## 6. Perguntas em aberto (para refinar quando você quiser)
- Vitória por STA: **nocaute imediato** ou só **critério de desempate**?
- A escolha de ação por turno deve ser **1 ação** ou um **mini-loadout** (ex.: gastar energia em mais de uma)?
- Quantos adversários no campo importam para o dano de 💥, ou abstraímos como "time" (uma barra de STA)?
