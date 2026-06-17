# ⚔️⚽ World Cup Beasts

> **Duelo de futebol por turnos + roguelike de deck-building**, num mundo gótico de feras onde tudo se decide numa partida (lógica Yu-Gi-Oh: "o duelo decide"). Você é uma fera-campeã que sobe numa gauntlet de 3 atos rumo ao título dos Imortais.

O jogo está em **Godot 4** na pasta [`godot/`](godot/). O motor de partida é determinístico (sem dado na resolução — a variância vem do sorteio de cartas), então **builds funcionam de forma confiável**.

---

## ▶️ Como rodar

1. Abra o **Godot 4** (4.2+; testado no 4.6.3).
2. **Import** → aponte para **`godot/project.godot`** → confirme.
3. Aperte **F5** (ou ▶). A cena principal já está configurada (`scenes/Main.tscn`).

Pela linha de comando:
```bash
godot --path godot            # roda direto
godot --path godot -e         # abre o editor
```

---

## 🎮 O loop de jogo

1. **Escolha sua fera** (4 jogáveis, cada uma com baralho e Super Lance próprios):
   - 🛡 **Cuirass** (tatu) — Tanque · passiva *Casco* (defesa reforçada)
   - 🐺 **Zab** (lobo) — Caçador · passiva *Matilha* (impacto drena fôlego)
   - 🐆 **Zak** (guepardo) — Veloz · passiva *Disparada* (contra-ataque ao roubar)
   - 🐓 **Foot** (galo) — Artilheiro · passiva *Esporão* (finaliza mais fácil)

2. **Suba no mapa roguelike** (estilo Slay the Spire): **3 atos**, cada um com colunas e bifurcações. Nós de ⚽ partida · 💀 elite · ❓ evento · 🎁 baú de relíquia (garantido) · 🛒 loja · 👑 chefe do ato.

3. **Vença os duelos** (a mecânica-coração — ver abaixo), ganhe 🪙 ouro, escolha **relíquias** (1 de 3), enfrente **eventos** narrativos e use a **loja** entre partidas.

4. **Repescagem** (❤️): 1 vida extra por corrida salva uma derrota fora de elite/chefe.

---

## ⭐ A mecânica-coração — as 4 BARRAS

Cada fera tem 4 barras que **acumulam entre turnos**:

1. **🎯 Finalização** — quando enche, **chuta ao gol** (zera ao disparar). O máximo escala com a dificuldade do inimigo.
2. **⚽ Controle de bola** — precisa ficar **> Desarme do oponente**, senão você **perde a posse**.
3. **🦵 Desarme** — se ficar **estritamente > Controle do inimigo**, você **rouba a bola**.
4. **🛡️ Defesa** — quando enche, **guarda uma defesa** que bloqueia o próximo chute (acumula).

- **Posse de bola:** com a bola, foque Finalização + Controle; sem ela, Desarme + Defesa.
- **Energia + cartas:** ~3 de energia/turno; cada carta custa energia e enche barras. Cartas de impacto drenam **fôlego** (vida) do oponente.
- **Passiva da fera:** cada fera tem uma habilidade passiva sempre ativa (sem botão) que molda seu estilo — defesa, desgaste, contra-ataque ou volume de gols.
- **Intenção do inimigo:** telegrafada por ícone (estilo Slay the Spire).

### Condições de vitória (3)
- **Placar** ao fim dos **15 turnos** (empate → morte súbita).
- **Goleada** de **≥5 gols** a qualquer momento.
- **Nocaute** por **fôlego (STA) zerado** — vale inclusive na morte súbita.

---

## 🗂️ Estrutura

```
football-autobattler/
├── README.md            ← este arquivo
├── ROADMAP.md           ← histórico de design + estado atual
├── beasts.html          ← protótipo web do duelo de cartas (LEGADO — fonte do port)
├── index.html           ← jogo de física antigo "Mundial dos Mitos" (LEGADO/arquivado)
└── godot/               ← O JOGO ATUAL (Godot 4)
    ├── project.godot
    ├── scenes/Main.tscn
    ├── assets/          ← arte pintada (ver assets/ASSETS.md) + fontes
    ├── scripts/
    │   ├── GameState.gd        # autoload: estado da corrida (feras, relíquias, eventos, mapa)
    │   ├── MatchEngine.gd      # MOTOR puro das 4 barras (determinístico, testável)
    │   ├── Cards.gd            # definição das cartas + baralhos
    │   ├── Main.gd             # roteador de telas (por sinais)
    │   ├── BeastSelectScreen.gd / MapScreen.gd / MatchScreen.gd
    │   ├── RelicScreen.gd / EventScreen.gd
    │   └── UIHelpers.gd        # cores e widgets reutilizáveis
    └── tests/
        ├── test_engine.gd      # 300 partidas IA×IA headless (gols, win%, exceções)
        └── test_parse.gd       # verifica parse de todos os scripts
```

`MatchEngine.gd` é **lógica pura** (sem nós/UI) — dá pra testar sem abrir tela.

---

## 🎨 Arte (em andamento)

O jogo está migrando da arte procedural (StyleBox + emoji) para **arte pintada gótica idêntica ao mock de referência**. A lista completa de imagens necessárias (nome, tamanho, descrição) está em **[`godot/assets/ASSETS.md`](godot/assets/ASSETS.md)**. Fontes (Cinzel / Oswald / Barlow Condensed) já incluídas. Enquanto os PNGs não chegam, o código usa placeholders e não quebra.

---

## ⚖️ Validação (headless)

Rodando `godot --headless --path godot --script tests/test_engine.gd`:

- **0 exceções** em 300 partidas IA×IA.
- Vitória do jogador **~55%** no espelho em `diff=1.0`; **~15–18%** em `diff=1.3` (a barra do jogador cresce com a dificuldade do inimigo).
- Curva da campanha: partida do Ato I `diff≈0.80`, elite `+0.12`, chefe final `≈1.32`.

---

## 🧪 Testes

```bash
godot --headless --path godot --script tests/test_engine.gd   # balanceamento
godot --headless --path godot --script tests/test_parse.gd    # parse de todos os scripts
```

---

*Histórico de design (slot machine descartado → cartas → port pra Godot) em [`ROADMAP.md`](ROADMAP.md).*
