
# =========================================================
# K-MEANS E VISUALIZAÇÃO DOS POKÉMON
# =========================================================

# Instale os pacotes caso ainda não estejam disponíveis:
# install.packages(c("ggplot2", "dplyr", "readr", "ggrepel"))

library(ggplot2)
library(dplyr)
library(readr)
library(ggrepel)


# =========================================================
# 1. LEITURA DOS DADOS
# =========================================================

pokemon <- read_csv("pokemon.csv")


# =========================================================
# 2. SELEÇÃO DOS ATRIBUTOS
# =========================================================

# A análise de agrupamento será feita utilizando
# os seis principais atributos de batalha.
stats <- pokemon %>%
  select(
    hp,
    attack,
    defense,
    `sp atk`,
    `sp def`,
    speed
  )


# =========================================================
# 3. CÁLCULO DOS STATS TOTAIS
# =========================================================

pokemon <- pokemon %>%
  mutate(
    total_stats =
      hp +
      attack +
      defense +
      `sp atk` +
      `sp def` +
      speed
  )


# =========================================================
# 4. PADRONIZAÇÃO DOS DADOS
# =========================================================

# Como o K-means utiliza distância euclidiana,
# os atributos são padronizados antes do agrupamento.
stats_scaled <- scale(stats)


# =========================================================
# 5. APLICAÇÃO DO K-MEANS
# =========================================================

set.seed(123)

km <- kmeans(
  stats_scaled,
  centers = 4,
  nstart = 50
)

# Guarda o cluster encontrado para cada Pokémon
pokemon$cluster <- km$cluster


# =========================================================
# 6. RESUMO DOS CLUSTERS
# =========================================================

# Calcula as médias dos atributos em cada cluster.
# Os clusters são então ordenados pela média dos
# stats totais para facilitar sua interpretação.

cluster_summary <- pokemon %>%
  group_by(cluster) %>%
  summarise(
    mean_total = mean(total_stats),
    mean_hp = mean(hp),
    mean_attack = mean(attack),
    mean_defense = mean(defense),
    mean_sp_atk = mean(`sp atk`),
    mean_sp_def = mean(`sp def`),
    mean_speed = mean(speed),
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(mean_total) %>%
  mutate(
    class = c(
      "Fraco",
      "Médio",
      "Forte",
      "Lendário"
    )
  )

print(cluster_summary)


# =========================================================
# 7. ADICIONAR AS CLASSES AO DATASET
# =========================================================

pokemon <- pokemon %>%
  left_join(
    cluster_summary %>%
      select(cluster, class),
    by = "cluster"
  ) %>%
  mutate(
    class = factor(
      class,
      levels = c(
        "Fraco",
        "Médio",
        "Forte",
        "Lendário"
      )
    )
  )


# =========================================================
# 8. SELEÇÃO DOS 10 POKÉMON MAIS FORTES
# =========================================================

# Os dez Pokémon com maior soma dos atributos
# serão destacados e identificados no gráfico.

top_10 <- pokemon %>%
  slice_max(
    order_by = total_stats,
    n = 10,
    with_ties = FALSE
  )

print(
  top_10 %>%
    select(
      name,
      total_stats,
      class,
      attack,
      defense
    ) %>%
    arrange(desc(total_stats))
)


# =========================================================
# 9. CRIAÇÃO DO GRÁFICO COM GGPLOT2
# =========================================================

p <- ggplot(
  pokemon,
  aes(
    x = attack,
    y = defense,
    color = class,
    size = hp
  )
) +

  # Todos os Pokémon
  geom_point(
    alpha = 0.55,
    stroke = 0
  ) +

  # Destaque dos dez Pokémon com maior pontuação
  geom_point(
    data = top_10,
    shape = 21,
    fill = "white",
    color = "black",
    size = 4.5,
    stroke = 0.9
  ) +

  # Nome dos dez Pokémon com maior pontuação
  geom_text_repel(
    data = top_10,
    aes(
      label = str_to_title(name)
    ),
    color = "black",
    size = 3.2,
    fontface = "bold",
    box.padding = 0.55,
    point.padding = 0.3,
    min.segment.length = 0,
    segment.color = "grey45",
    segment.linewidth = 0.4,
    max.overlaps = Inf,
    show.legend = FALSE
  ) +

  # Tamanho dos pontos representa o HP
  scale_size_continuous(
    range = c(2.5, 8),
    name = "HP"
  ) +

  # Cores utilizadas para representar as classes
  scale_color_manual(
    values = c(
      "Fraco" = "#9E9E9E",
      "Médio" = "#4C78A8",
      "Forte" = "#F58518",
      "Lendário" = "#E45756"
    ),
    labels = c(
      "Fraco" = "Weak",
      "Médio" = "Medium",
      "Forte" = "Strong",
      "Lendário" = "Legendary"
    ),
    name = "K-means class"
  ) +

  # Informações apresentadas no gráfico
  labs(
    title = "Classification of Pokémon by Battle Attributes",
    subtitle = "K-means clustering (k = 4) based on standardized combat statistics",
    x = "Attack",
    y = "Defense",
    caption = paste0(
      "Clusters were ranked according to mean total base statistics. ",
      "Outlined points and labels indicate the 10 Pokémon with the highest total stats."
    )
  ) +

  # Tema visual
  theme_classic(
    base_size = 13
  ) +

  theme(
    plot.title = element_text(
      size = 18,
      face = "bold"
    ),

    plot.subtitle = element_text(
      size = 11.5,
      color = "grey30",
      margin = margin(b = 14)
    ),

    axis.title = element_text(
      size = 12,
      face = "bold"
    ),

    axis.text = element_text(
      size = 10,
      color = "black"
    ),

    legend.title = element_text(
      size = 10.5,
      face = "bold"
    ),

    legend.text = element_text(
      size = 9.5
    ),

    legend.key.height = unit(
      0.55,
      "cm"
    ),

    plot.caption = element_text(
      size = 8.5,
      color = "grey40",
      hjust = 0,
      margin = margin(t = 10)
    ),

    plot.margin = margin(
      12,
      18,
      12,
      12
    )
  )


# =========================================================
# 10. EXIBIR O GRÁFICO
# =========================================================

p


# =========================================================
# 11. EXPORTAR OS GRÁFICOS
# =========================================================

# Cria a pasta de saída caso ela não exista.
if (!dir.exists("output")) {
  dir.create(
    "output",
    recursive = TRUE
  )
}


# Salva a figura em PNG
ggsave(
  filename = "output/pokemon_kmeans_top10.png",
  plot = p,
  width = 8,
  height = 5.8,
  units = "in",
  dpi = 300,
  bg = "white"
)


# Salva também uma versão vetorial em PDF
ggsave(
  filename = "output/pokemon_kmeans_top10.pdf",
  plot = p,
  width = 8,
  height = 5.8,
  units = "in"
)

cat("\nGráficos salvos na pasta 'output'.\n")

