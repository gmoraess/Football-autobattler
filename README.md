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

4. **A partida ao vivo** — campo com zonas e bola reativa. A simulação roda sozinha; **você ativa táticas nos momentos-chave** gastando energia. As habilidades dos jogadores agem automaticamente. Controles de velocidade (1×/2×/3×), pausa e "simular".

### Arquétipos com mecânicas próprias (não são só números)
- 🔥 **Centroavante de Fogo** — cada gol aumenta o *calor* do campo, queimando o fôlego dos **dois** times.
- 🧊 **Goleira de Cristal** — defende quase tudo, mas **trinca** a cada defesa e perde força se sobrecarregada.
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

O motor foi testado de forma automatizada (~500 partidas simuladas, **0 erros**):

| Perfil de jogo | Taxa de título (corrida inteira) |
|---|---|
| Sem comprar nada e sem usar táticas | **0%** |
| Comprando reforços/relíquias + usando táticas | **~22%** |

Ou seja: **você não vence só apertando "jogar"** — a build e o timing das táticas decidem. É o contraste que mostra que a camada estratégica tem peso (o coração do gênero).

---

## ✂️ O que foi cortado de propósito (é MVP)

- Arte/animações finais (o campo e a bola são CSS simples).
- Sistema de save/persistência entre sessões.
- Áudio.
- Progressão meta entre corridas (desbloqueios, novas nações).
- Eventos roguelike mais ricos (escolhas narrativas, mutadores).
- Balanceamento fino por nação (todas são jogáveis, mas não milimetricamente equilibradas).

## 🚀 Próximos passos naturais (se a ideia validar)

1. Mais profundidade tática na partida (formações, posicionamento por zona, substituições ao vivo).
2. Pool maior de jogadores, relíquias e **sinergias** entre arquétipos.
3. Eventos roguelike entre fases (não só a loja).
4. Polimento visual + o **evento sazonal de lançamento** durante a Copa real.

---

*Tecnologia: HTML + CSS + JavaScript puro (vanilla), tudo em um único arquivo `index.html`. Escolhido para máxima portabilidade — abre em qualquer lugar, inclusive no celular, sem fricção de validação.*
