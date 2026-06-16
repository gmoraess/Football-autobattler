# ⚔️⚽ World Cup Beasts — versão Godot 4

Port do protótipo web (`../beasts.html`) para **Godot 4.x**. Mesma mecânica das
**4 barras acumulativas** (Finalização / Controle / Desarme / Defesa) + energia,
posse de bola, intenção do inimigo por ícone e Super Lance.

## ▶️ Como abrir e rodar

1. Abra o **Godot 4** (4.2 ou mais novo).
2. Na janela inicial, clique em **Import** (Importar).
3. Aponte para o arquivo **`godot/project.godot`** desta pasta e confirme.
4. Com o projeto aberto, aperte **F5** (ou o ▶ no canto superior direito) para rodar.
   - A cena principal já está configurada (`scenes/Main.tscn`).

## 🎮 Como jogar

- Você é o **Couraça** (azul). Toque/clique nas **cartas** da mão para encher suas barras
  (gasta **energia**, 3 por turno).
- **Com a posse** (marcador "⚽ POSSE DE BOLA"): foque **Finalização** + **Controle**.
- **Sem a posse**: foque **Desarme** + **Defesa**.
- Aperte **▶ FIM DE TURNO** para o inimigo jogar e o turno resolver:
  - Desarme > Controle do oponente → **rouba a bola**.
  - Barra de Finalização cheia → **chute** (uma Defesa guardada bloqueia).
  - Barra de Defesa cheia → **guarda** uma defesa (acumula).
- Vence por **gols** (placar ao fim dos 15 turnos / morte súbita), **goleada (≥5)**
  ou **nocaute de fôlego (KO)**.

## 🗂️ Estrutura

```
godot/
├── project.godot          # config do projeto (Godot 4)
├── scenes/Main.tscn       # cena raiz (um Control com Main.gd)
└── scripts/
    ├── Cards.gd           # definição das cartas + baralhos (class_name Cards)
    ├── MatchEngine.gd     # MOTOR puro das 4 barras (class_name MatchEngine) — testável
    └── Main.gd            # monta o HUD por código + conduz a partida
```

- **`MatchEngine.gd` é lógica pura** (sem nós/UI): é a tradução fiel do motor do
  `beasts.html`. Dá pra testar/automatizar sem abrir tela.
- **`Main.gd`** constrói toda a interface em código (sem precisar montar a árvore de
  nós na mão) e desenha o tema "arena gótica" com `StyleBoxFlat`.

## ⚠️ Sobre os ícones (emoji)

A fonte padrão do Godot **pode não desenhar emojis coloridos** (⚽🎯🛡️ podem aparecer
como quadradinhos "tofu"). Isso **não afeta a jogabilidade**, só o visual. Para corrigir:

1. Baixe uma fonte com emoji (ex.: **Noto Emoji** — a versão *monocromática*
   `NotoEmoji-Regular.ttf` funciona melhor no Godot que a colorida).
2. Coloque o `.ttf` em `godot/` (ex.: `fonts/NotoEmoji-Regular.ttf`).
3. **Project → Project Settings → General → GUI → Theme → Custom Font** e aponte para ela
   (ou crie um `Theme` com `fallback`/`Default Font`).

Como alternativa rápida, dá pra trocar os emojis por texto/letras em `Cards.gd` e nos
rótulos de `Main.gd`.

## 🔜 Próximos passos (não incluídos neste scaffold)

Este é o **núcleo jogável** (uma partida avulsa, Couraça x Górtax). Ainda **não** portei:
relíquias, mapa roguelike de 3 atos, loja, eventos e seleção de fera — tudo isso já existe
no `beasts.html` e pode ser portado por cima do `MatchEngine` quando você quiser.
