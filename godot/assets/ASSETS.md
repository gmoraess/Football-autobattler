# Manifesto de Assets — World Cup Beasts

> Gere cada PNG com o nome **exato** abaixo e coloque na subpasta indicada.
> O código procura por esses caminhos; se faltar, usa um placeholder (não quebra).
> Estilo de referência: a imagem `e1176e04...png` (arte pintada, gótica, dourada).
> **Transparência**: onde indicado "transparente", o fundo precisa ser alfa (PNG com canal alfa), sem fundo de cenário.
> **Direção**: feras jogáveis olham **pra direita ▶** (ficam à esquerda); inimigos e chefes olham **pra esquerda ◀** (ficam à direita). Não espelho nada — gere cada um já no lado certo.

Resolução-base do jogo: **1920×1080 (16:9)**.

---

## LOTE 1 — Essenciais da tela de partida  (12 imagens)
Tudo que a imagem de referência mostra. Gere este lote primeiro.

### `assets/bg/`
| Arquivo | Tamanho | Descrição |
|---|---|---|
| `arena.png` | 1920×1080 | Fundo do estádio gótico: arena escura, catedral ao fundo, tochas acesas nas laterais. SEM personagens, SEM UI. É o pano de fundo do duelo. |

### `assets/beasts/`  (PNG transparente, corpo inteiro, **virado pra direita ▶** — ficam à esquerda)
| Arquivo | Tamanho | Descrição |
|---|---|---|
| `couraca.png`   | 800×1000 | **Couraça** — tatu/armadillo blindado, guerreiro tanque de armadura pesada. |
| `gortax.png`    | 800×1000 | **Górtax** — minotauro/touro artilheiro, chifres, postura agressiva. |
| `aurelio.png`   | 800×1000 | **Aurélio** — falcão/águia humanoide, maestro elegante, asas. |
| `mandibula.png` | 800×1000 | **Mandíbula** — jacaré/crocodilo humanoide brutal, mandíbula forte. |

### `assets/icons/`  (PNG transparente, quadrado)
| Arquivo | Tamanho | Descrição |
|---|---|---|
| `stat_fin.png`  | 128×128 | Ícone **Finalização**: alvo/mira vermelho. |
| `stat_con.png`  | 128×128 | Ícone **Controle de Bola**: bola azul / círculo de controle. |
| `stat_des.png`  | 128×128 | Ícone **Desarme**: chuteira/carrinho roubando a bola. |
| `stat_def.png`  | 128×128 | Ícone **Defesa**: escudo verde. |
| `energy.png`    | 128×128 | **Gema de energia**: diamante/cristal azul brilhante. |
| `posse.png`     | 256×256 | Selo dourado circular **"POSSE DE BOLA"** (com a bola no centro). |
| `ball.png`      | 128×128 | Bola de futebol simples (usada no mini-campo e cartas de passe). |

---

## LOTE 2 — Inimigos e chefes  (12 imagens)
Mesmo formato das feras: `assets/beasts/`, 800×1000, transparente — mas virados **pra esquerda ◀** (ficam à direita, encarando o jogador).

### Inimigos normais (Ato 1 → 3)
| Arquivo | Criatura |
|---|---|
| `rinoceronte.png` | Rinoceronte Sombrio |
| `lobo.png`        | Lobo da Névoa |
| `urso.png`        | Urso do Norte |
| `escorpiao.png`   | Escorpião Ferreiro |
| `tigre.png`       | Tigre Relâmpago |
| `gorila.png`      | Gorila das Sombras |
| `dragao.png`      | Dragão de Jade |
| `serpente.png`    | Serpente Estelar |
| `fenix.png`       | Fênix das Cinzas |

### Chefes (1 por ato)
| Arquivo | Criatura |
|---|---|
| `boss_mantis.png`  | Mantis da Tempestade (louva-a-deus) |
| `boss_leao.png`    | Leão Dourado |
| `boss_quetzal.png` | Quetzal, a Serpente Imortal (dragão-serpente) |

---

## LOTE 3 — Ilustrações de carta  (22 imagens)
`assets/cards/`, **400×300 (paisagem)**, fundo pode ser cheio (eu coloco a moldura/preço/nome por cima). Nome do arquivo = id da carta.

| Arquivo | Carta | Cena sugerida |
|---|---|---|
| `passe.png`      | Passe | Bola sendo tocada rente ao chão. |
| `drible.png`     | Drible | Fera driblando, bola nos pés. |
| `meialua.png`    | Meia-Lua | Giro/meia-lua com a bola. |
| `caneta.png`     | Caneta | Bola passando entre as pernas do rival. |
| `visao.png`      | Visão de Jogo | Olhar/visão tática do campo. |
| `cruzamento.png` | Cruzamento | Bola cruzada pela lateral em direção à área. |
| `finaliza.png`   | Finalização | Bola em chamas indo pro gol. |
| `lancamento.png` | Lançamento | Lançamento longo, bola no ar. |
| `colocado.png`   | Chute Colocado | Bola fazendo curva no canto. |
| `bicuda.png`     | Bicuda | Chute violento, impacto/explosão. |
| `voleio.png`     | Voleio | Voleio acrobático no ar. |
| `cavadinha.png`  | Cavadinha | Bola cavada por cima do goleiro. |
| `desarme.png`    | Desarme | Roubada de bola limpa. |
| `carrinho.png`   | Carrinho | Carrinho deslizando pra desarmar. |
| `botinha.png`    | Antecipação | Antecipar e tirar a bola. |
| `pancada.png`    | Pancada | Choque físico forte. |
| `ombro.png`      | Ombrada | Ombro a ombro, empurrão. |
| `solada.png`     | Solada | Sola da chuteira na bola. |
| `marcacao.png`   | Marcação | Marcação cerrada no adversário. |
| `defesa.png`     | Defesa | Goleiro/defensor bloqueando. |
| `bloqueio.png`   | Bloqueio | Corpo bloqueando o chute. |
| `muralha.png`    | Muralha | Barreira/parede defensiva. |

---

## LOTE 4 — Molduras, mapa e relíquias  (17 imagens)

### `assets/frames/`  (9-slice — deixe bordas de espessura uniforme; eu estico o miolo)
| Arquivo | Tamanho | Descrição |
|---|---|---|
| `panel.png`       | 256×256 | Painel de pedra escura com borda de ouro/bronze ornamentada (usado atrás de barras, listas, etc.). |
| `card_frame.png`  | 300×400 | Moldura de carta: borda dourada ornamentada, miolo transparente (a arte da carta aparece dentro). |
| `button_gold.png` | 256×96  | Botão dourado ornamentado (FIM DE TURNO, etc.). |
| `banner_crest.png`| 200×120 | Estandarte/brasão dourado dos cantos superiores (genérico — espelho pro outro lado). |

### `assets/icons/`  (mapa e UI — 128×128, transparente)
| Arquivo | Descrição |
|---|---|
| `node_partida.png` | Nó de partida normal (monstro comum) — ícone de combate. |
| `node_elite.png`   | Nó elite — caveira/monstro forte. |
| `node_bau.png`     | Nó baú/tesouro garantido. |
| `node_evento.png`  | Nó de evento — ponto de interrogação místico. |
| `node_loja.png`    | Nó de loja — saco de moedas/mercador. |
| `node_boss.png`    | Nó de chefe — coroa/caveira grande. |
| `gold.png`         | Moeda de ouro. |
| `book.png`         | Livro (ajuda/regras — canto inferior direito). |
| `gear.png`         | Engrenagem (configurações). |

### `assets/icons/relics/`  (96×96, transparente — relíquias)
| Arquivo | Relíquia |
|---|---|
| `escudo_antigo.png`   | Escudo Antigo |
| `bota_craque.png`     | Bota de Craque |
| `faixa_capitao.png`   | Faixa do Capitão |
| `coracao_ferro.png`   | Coração de Ferro |
| `luvas_goleiro.png`   | Luvas do Goleiro |
| `chuteira_rapida.png` | Chuteira Rápida |
| `amuleto_gol.png`     | Amuleto do Gol |
| `cristal_fury.png`    | Cristal da Fúria |
| `capa_sombria.png`    | Capa Sombria |
| `talisma_ouro.png`    | Talismã de Ouro |
| `sindrome_fera.png`   | Síndrome da Fera |

> (Relíquias = 11 arquivos; somadas às 9 de mapa/UI dá os 17 do Lote 4 + 11.)

---

## Resumo
- Lote 1: 12 · Lote 2: 12 · Lote 3: 22 · Lote 4: 9 molduras/UI + 11 relíquias
- **Total: ~66 PNGs**
- Comece pelo **Lote 1** — com ele a tela de partida já fica idêntica à referência.
