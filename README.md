# ⚽👑 Mundial dos Mitos — MVP

> Um **autobattler roguelike de futebol mítico** com a estrutura e o gancho de uma Copa do Mundo, mas com identidade fantástica própria (sem problema de licença de seleções reais).

Este é um **MVP de validação**: o objetivo é colocar o loop completo na sua mão em poucos minutos para você sentir se a ideia "gruda" — não é um jogo finalizado nem com arte final.

---

## ▶️ Como jogar (zero instalação)

Abra o arquivo **`index.html`** em qualquer navegador (PC ou celular). Só isso — é um único arquivo, sem build, sem dependências, sem servidor.

```
# duplo-clique no index.html, ou:
open index.html        # macOS
xdg-open index.html    # Linux
start index.html       # Windows
```

---

## 🎮 O que tem no MVP (o loop completo)

1. **Escolha sua Seleção Imortal** — 4 nações fictícias, cada uma com identidade, elenco inicial e **tática-assinatura** próprios:
   - ☀️ **Reino do Sol Eterno** — agressivo; ganha ataque permanente a cada gol marcado.
   - 🌫️ **República das Brumas** — controle/ilusão; rouba a posse de bola.
   - 🔱 **Confederação das Profundezas** — defensivo; vence por desgaste (regenera fôlego).
   - ⚡ **Clã das Tormentas** — velocidade/caos; contra-ataques relâmpago.

2. **Suba na Copa** — bracket completo: **Fase de Grupos (3 jogos) → Oitavas → Quartas → Semi → A FINAL (chefe)**. No mata-mata, derrota encerra a corrida; empate vai para os **pênaltis**.

3. **Entre as partidas (camada roguelike)** — gaste 🪙 *Ouro Místico* no **Mercado de Transferências**:
   - **Jogadores místicos** (recrutamento) com raridades Comum/Raro/Lendário.
   - **Táticas Ancestrais** (relíquias) — bônus permanentes (ex.: +ataque global, +velocidade, goleiro reforçado, energia mais rápida…).
   - **Escalação**: elenco reduzido — você escolhe **5 titulares**, cada um uma unidade com peso real.

4. **A partida ao vivo, com FÍSICA 2D** (canvas) — campo renderizado em tempo real, jogadores como unidades com **anel de fôlego (vida)** em volta, e a **bola como projétil de verdade** (velocidade, atrito, quique, knockback). A física roda sozinha (*autobattler assistível*); você intervém nos momentos-chave gastando energia. Controles de velocidade (1×/2×/3×), pausa e "simular".

### ⭐ As mecânicas-coração da v0.2: física + stamina como vida
- **A bola é uma arma.** Um chute não é "gol ou defesa" binário — é um projétil que viaja pelo campo e pode **acertar jogadores no caminho**.
- **Fôlego = vida.** Cada jogador tem fôlego que cai com o tempo **e ao ser atingido pela bola**. Quem zera **cai (atordoado)** e seu time joga **com um a menos** por alguns segundos — pressão espacial, não só um número menor.
- **🎯 Chute de Poder** (intervenção principal) — você designa seu artilheiro; ele **carrega** (telégrafo visual com aura) e solta um chute devastador, com **rastro, hitstop e screen-shake**, que arranca muito fôlego de quem for atingido.
- **VFX por nação/arquétipo** — o mesmo evento de física vira fogo ☄️, raio ⚡ ou névoa 🌀.
- **Builds e counters de fôlego** — times que vencem por impacto (canhão) vs. muralhas que absorvem vs. drenagem; e inimigos/chefes podem **mirar a sua peça-chave** (ex.: derrubar seu Meia Ancião) — você tem que **protegê-la** ou usar **💚 Reforço de Fôlego** para reanimar.

### Arquétipos com mecânicas próprias (não são só números)
- 🔥 **Centroavante de Fogo** — cada gol aumenta o *calor* do campo, queimando o fôlego dos **dois** times.
- 🧊 **Goleira de Cristal** — defende quase tudo, mas **trinca** a cada defesa e perde fôlego se sobrecarregada.
- 🧙 **Meia Ancião** — fraco fisicamente, mas dita o ritmo e **potencializa o controle** dos companheiros.
- ⚡ **Lâmina Veloz**, 🗿 **Muralha Ancestral**, 🎴 **Maestro das Brumas** e outros, cada um com um efeito.

---

## ✅ O que validar com este protótipo

Jogue 2–3 corridas e observe:

- **A decisão entre rodadas é interessante?** (comprar jogador X vs relíquia Y, quem escalar). É aqui que mora o jogo.
- **A partida é uma "recompensa visual" satisfatória** de assistir e intervir, ou é passiva demais?
- **Ativar a tática no momento certo dá sensação de impacto?**
- **As identidades das nações criam estilos de jogo realmente diferentes?**
- **A progressão (snowball) é gostosa** — dá pra sentir o time ficando mais forte?

---

## ⚖️ Sobre o balanceamento

O motor de física foi testado de forma automatizada (~500 partidas simuladas em modo headless, **0 erros**, média de ~2,5 gols/partida, ~3 jogadores derrubados por partida):

| Perfil de jogo | Taxa de título (corrida inteira) |
|---|---|
| Sem comprar nada e sem usar táticas | **~12%** |
| Comprando reforços/relíquias + usando táticas | **~35%** |

Ou seja: **jogar bem ~triplica sua chance de ser campeão** — a build e o timing das táticas/chutes de poder decidem. É o contraste que mostra que a camada estratégica tem peso (o coração do gênero).

---

## ✂️ O que foi cortado de propósito (é MVP)

- Arte final (jogadores são discos com anel de fôlego; VFX são partículas simples de canvas).
- Áudio (o impacto pede som — é um próximo passo óbvio para o "suco").
- Sistema de save/persistência entre sessões.
- Progressão meta entre corridas (desbloqueios, novas nações).
- Eventos roguelike mais ricos (escolhas narrativas, mutadores).
- Mira manual do chute (hoje você *comanda* o chute de poder; o jogador mira automático).
- Balanceamento fino por nação (todas jogáveis, não milimetricamente equilibradas).

## 🚀 Próximos passos naturais (se a ideia validar)

1. **Som + mais juice** no impacto (o feel da física dobra com áudio e câmera).
2. Mira/timing manual do chute de poder para quem quiser mais skill (modo "ação").
3. Pool maior de jogadores, relíquias e **sinergias**; arquétipos e chefes que atacam o fôlego.
4. Eventos roguelike entre fases (não só a loja).
5. Polimento visual + o **evento sazonal de lançamento** durante a Copa real.

---

*Tecnologia: HTML + CSS + JavaScript puro (vanilla), tudo em um único arquivo `index.html`. Escolhido para máxima portabilidade — abre em qualquer lugar, inclusive no celular, sem fricção de validação.*
