# ⚔️⚽ World Cup Beasts — Godot 4

Port do protótipo web (`../beasts.html`) para **Godot 4.x** (testado no 4.6.3), já
com a **campanha roguelike completa** por cima do motor de partida.

## ▶️ Como abrir e rodar

1. Abra o **Godot 4** (4.2 ou mais novo).
2. **Import** → aponte para **`godot/project.godot`** → confirme.
3. Aperte **F5** (ou ▶ no canto superior direito). Cena principal: `scenes/Main.tscn`.

Linha de comando: `godot --path .` (roda) · `godot --path . -e` (editor).

## 🎮 Fluxo do jogo

`Seleção de fera → Mapa (3 atos) → Partida / Evento / Relíquia / Loja → Vitória ou Derrota`

- **Escolha sua fera** (Cuirass, Zab, Zak ou Foot) — cada uma tem baralho e uma passiva única.
- No **mapa**, clique num nó iluminado pra avançar (bifurcações estilo Slay the Spire).
- Na **partida**: clique nas **cartas** pra encher as 4 barras (gasta energia), depois **▶ FIM DE TURNO**.
  - Desarme > Controle do oponente → **rouba a bola**.
  - Finalização cheia → **chute** (uma Defesa guardada bloqueia).
  - Defesa cheia → **guarda** uma defesa (acumula).
  - Vence por **gols** (15 turnos / morte súbita), **goleada (≥5)** ou **nocaute de fôlego (KO)**.
- Entre nós: **relíquias** (1 de 3), **eventos** narrativos, **loja**. ❤️ Repescagem = 1 vida extra/corrida.

## 🗂️ Estrutura

```
godot/
├── project.godot              # config (autoload GameState; janela 16:9)
├── scenes/Main.tscn           # cena raiz (Control + Main.gd)
├── assets/                    # arte pintada + fontes — ver assets/ASSETS.md
└── scripts/
    ├── GameState.gd           # AUTOLOAD: estado da corrida — feras, relíquias, eventos, geração de mapa
    ├── MatchEngine.gd         # MOTOR puro das 4 barras (sem UI, determinístico, testável)
    ├── Cards.gd               # cartas + baralhos
    ├── Main.gd                # roteador de telas (por sinais)
    ├── BeastSelectScreen.gd   # seleção de fera (4 opções)
    ├── MapScreen.gd           # mapa roguelike (3 atos × colunas × raias)
    ├── MatchScreen.gd         # HUD da partida (consome contexto do GameState)
    ├── RelicScreen.gd         # escolha de relíquia (1 de 3)
    ├── EventScreen.gd         # eventos narrativos
    └── UIHelpers.gd           # cores e fábricas de widget reutilizáveis
```

- **`MatchEngine.gd` é lógica pura** — tradução fiel do motor do `beasts.html`, testável sem tela.
- **Relíquias** entram no motor via `p_mods` (Dicionário) em `MatchEngine.begin()` — a lógica do motor fica pura.
- A UI é montada **por código** (sem montar a árvore de nós na mão).

## 🎨 Arte

Migrando de procedural (StyleBox + emoji) para **arte pintada gótica**. A lista completa de
PNGs necessários está em **[`assets/ASSETS.md`](assets/ASSETS.md)**. Fontes Cinzel / Oswald /
Barlow Condensed já em `assets/fonts/`. Faltando os PNGs, o código cai em placeholder.

## 🧪 Testes (headless)

```bash
godot --headless --path . --script tests/test_engine.gd   # 300 partidas IA×IA: gols, win%, exceções
godot --headless --path . --script tests/test_parse.gd    # parse de todos os scripts
```

Última validação: **0 exceções**, ~55% de vitória do jogador no espelho (`diff=1.0`), todos os scripts com parse OK.
