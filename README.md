# Ferramentas Computacionais para Modelagem

## Análise de Pokémon com K-means

Este projeto foi desenvolvido como parte da disciplina **Ferramentas Computacionais para Modelagem**.

A ideia do exercício é usar um conjunto de dados de Pokémon para aplicar uma técnica simples de **aprendizado não supervisionado** e, depois, visualizar os resultados de uma forma que seja fácil de interpretar.

Como os Pokémon possuem vários atributos de batalha, a proposta foi verificar se esses atributos permitem encontrar grupos de Pokémon com características semelhantes.

Para isso, foi utilizado o algoritmo **K-means**, considerando quatro grupos. Depois do agrupamento, os clusters foram organizados de acordo com seus valores médios de atributos e receberam, de forma mais intuitiva e também um pouco "na brincadeira", os nomes:

* **Fraco**
* **Médio**
* **Forte**
* **Lendário**

Vale destacar que essas categorias não são classificações oficiais dos Pokémon. Elas são apenas uma forma de interpretar os grupos encontrados pelo algoritmo.

---

## Sobre os dados

O conjunto de dados contém informações sobre diferentes Pokémon, incluindo:

* HP
* Attack
* Defense
* Sp. Attack
* Sp. Defense
* Speed
* Tipo principal
* Tipo secundário
* Altura
* Peso
* Número na Pokédex

Para o agrupamento, foram utilizados apenas os seis atributos de batalha:

`HP`, `Attack`, `Defense`, `Sp. Attack`, `Sp. Defense` e `Speed`.

Além disso, foi calculado o **Total Stats**, que corresponde à soma desses seis atributos.

---

## Metodologia

### 1. Preparação dos dados

Os seis atributos de batalha foram selecionados para a análise.

Como o K-means utiliza distância euclidiana para determinar a proximidade entre as observações, os atributos foram **padronizados** antes da aplicação do algoritmo.

Isso evita que uma variável tenha influência excessiva apenas por estar originalmente em uma escala diferente das demais.

### 2. K-means

Foi utilizado o algoritmo K-means com:

* **4 clusters**
* **50 inicializações (`nstart = 50`)**
* semente aleatória fixa (`set.seed(123)`)

O algoritmo agrupa os Pokémon de acordo com a similaridade dos seus atributos de batalha.

Depois do agrupamento, os clusters são ordenados pela média de seus `Total Stats`.

Assim, o cluster com menor média recebe o nome **Fraco**, enquanto o de maior média recebe o nome **Lendário**.

### 3. Seleção dos Pokémon de destaque

Para facilitar a leitura do gráfico, foram selecionados os **10 Pokémon com maior Total Stats**.

Esses Pokémon recebem um destaque visual e seus nomes são apresentados diretamente no gráfico.

---

## Visualização

O gráfico principal foi desenvolvido utilizando o **ggplot2**.

A visualização apresenta:

* **Eixo X:** Attack
* **Eixo Y:** Defense
* **Cor:** classe obtida pelo K-means
* **Tamanho dos pontos:** HP
* **Rótulos:** Top 10 Pokémon em Total Stats

Dessa forma, o gráfico permite observar simultaneamente a relação entre Attack e Defense, a classificação dos clusters e a magnitude do HP.

A figura também é exportada em dois formatos:

* PNG, com resolução de 300 dpi
* PDF, em formato vetorial

Os arquivos são armazenados automaticamente na pasta `output/`.

---

## Estrutura do projeto

```text
Projeto_FCM/
│
├── pokemon.R
├── pokemon.csv
├── output/
│   ├── pokemon_kmeans_top10.png
│   └── pokemon_kmeans_top10.pdf
└── README.md
```

---

## Tecnologias utilizadas

A análise foi desenvolvida em **R**, utilizando principalmente:

* `readr` — leitura dos dados
* `dplyr` — manipulação dos dados
* `ggplot2` — criação dos gráficos
* `ggrepel` — posicionamento dos rótulos no gráfico
* `kmeans` — agrupamento não supervisionado

---

## Como executar

Com o R instalado, basta abrir o arquivo `pokemon.R` e executar o script.

Caso os pacotes ainda não estejam instalados, execute:

```r
install.packages(c(
  "ggplot2",
  "dplyr",
  "readr",
  "ggrepel"
))
```

Depois, execute o script normalmente.

O programa irá:

1. carregar o arquivo `pokemon.csv`;
2. preparar os atributos;
3. padronizar os dados;
4. executar o K-means;
5. identificar e resumir os clusters;
6. classificar os grupos;
7. selecionar os 10 Pokémon com maior Total Stats;
8. gerar o gráfico;
9. criar a pasta `output/`, caso ela não exista;
10. salvar as figuras em PNG e PDF.

---

## Observação

A classificação **Fraco, Médio, Forte e Lendário** é apenas uma interpretação dos clusters encontrados pelo K-means. O algoritmo não recebe essas categorias como informação de entrada.

Em outras palavras, o modelo não "sabe" o que é um Pokémon lendário. Ele apenas identifica grupos de Pokémon com atributos estatisticamente semelhantes. A classificação foi atribuída posteriormente com base na média dos atributos de cada cluster.

Essa foi justamente a parte mais divertida do exercício: deixar o algoritmo encontrar os grupos e depois tentar interpretar o que eles representam.

---

## Objetivo do exercício

Mais do que classificar Pokémon, o objetivo é praticar um fluxo simples de modelagem computacional:

**dados → preparação → padronização → aprendizado não supervisionado → interpretação → visualização**

A ideia é mostrar como uma técnica de agrupamento pode ser aplicada a um conjunto de dados real e transformada em uma visualização que facilite a interpretação dos resultados.
