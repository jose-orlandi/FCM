# ============================================================
# INFLUENZA AVIÁRIA - PERU
# Extração de dados do PDF + análise espacial
#
# Ferramentas Computacionais para Modelagem
# ============================================================


# ============================================================
# 1. PACOTES
# ============================================================

pacotes <- c(
  "pdftools",
  "stringr",
  "dplyr",
  "tidyr",
  "purrr",
  "readr",
  "lubridate",
  "sf",
  "ggplot2",
  "viridis",
  "geodata",
  "scales"
)

instalados <- rownames(installed.packages())

for (p in pacotes) {
  if (!p %in% instalados) {
    install.packages(p)
  }
}

library(pdftools)
library(stringr)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)
library(lubridate)
library(sf)
library(ggplot2)
library(viridis)
library(geodata)
library(scales)


# ============================================================
# 2. ESTRUTURA DE DIRETÓRIOS
# ============================================================

dir.create("data", showWarnings = FALSE)
dir.create("data/raw", showWarnings = FALSE)
dir.create("data/processed", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)


# ============================================================
# 3. ARQUIVO PDF
# ============================================================

pdf_file <- "C:\\Users\\vitor\\Documents\\Ferramentas Computacionais de Modelagem\\Projeto_FCM\\Peru - Evento 4732.pdf"

if (!file.exists(pdf_file)) {
  stop(
    paste0(
      "\nPDF não encontrado.\n",
      "Coloque o arquivo em:\n",
      normalizePath("data/raw", mustWork = FALSE),
      "\n"
    )
  )
}


# ============================================================
# 4. EXTRAÇÃO DO TEXTO
# ============================================================

cat("Lendo PDF...\n")

paginas <- pdf_text(pdf_file)

cat(
  "Número de páginas:",
  length(paginas),
  "\n"
)


# ============================================================
# 5. LIMPEZA DO TEXTO
# ============================================================

limpar_texto <- function(x) {

  x %>%

    # normalizar quebras de linha
    str_replace_all("\r", "\n") %>%

    # espaços repetidos
    str_replace_all("[ \t]+", " ") %>%

    # linhas vazias repetidas
    str_replace_all("\n+", "\n") %>%

    str_trim()
}


paginas_limpa <- map_chr(
  paginas,
  limpar_texto
)


# ============================================================
# 6. FUNÇÕES AUXILIARES
# ============================================================

extrair_numero <- function(x) {

  if (length(x) == 0 || is.na(x)) {
    return(NA_real_)
  }

  x <- str_trim(x)

  if (x %in% c("", "-", "–", "—")) {
    return(NA_real_)
  }

  x <- str_replace_all(x, ",", "")

  suppressWarnings(
    as.numeric(x)
  )
}


extrair_data <- function(x) {

  if (length(x) == 0 || is.na(x)) {
    return(as.Date(NA))
  }

  x <- str_trim(x)

  suppressWarnings(
    as.Date(x, format = "%Y/%m/%d")
  )
}


# ============================================================
# 7. EXTRAIR ID + DATAS
# ============================================================

extrair_identificacao <- function(texto) {

  resultado <- str_match(
    texto,
    "(\\d{10})\\s+(\\d{4}/\\d{2}/\\d{2})\\s+(\\d{4}/\\d{2}/\\d{2})"
  )

  tibble(
    outbreak_id = resultado[, 2],
    start_date = extrair_data(resultado[, 3]),
    end_date = extrair_data(resultado[, 4])
  )
}


# ============================================================
# 8. EXTRAIR LOCALIZAÇÃO ADMINISTRATIVA
# ============================================================

extrair_administracao <- function(texto) {

  # Procura o bloco entre SECOND ADMINISTRATIVE DIVISION
  # e LOCATION

  bloco <- str_match(
    texto,
    "FIRST ADMINISTRATIVE DIVISION SECOND ADMINISTRATIVE DIVISION THIRD ADMINISTRATIVE DIVISION EPIDEMIOLOGICAL UNIT\\s+(.+?)\\s+LOCATION"
  )[, 2]

  if (is.na(bloco)) {

    return(
      tibble(
        adm1 = NA_character_,
        adm2 = NA_character_,
        adm3 = NA_character_,
        epidemiological_unit = NA_character_
      )
    )
  }

  # O formato do PDF coloca os quatro campos em sequência
  partes <- str_split(
    bloco,
    "\\s+",
    simplify = TRUE
  )

  partes <- partes[partes != ""]

  # Para o relatório real, usamos uma estratégia baseada
  # na linha após os cabeçalhos quando possível.

  linhas <- str_split(
    texto,
    "\n",
    simplify = TRUE
  )

  linhas <- str_trim(linhas)
  linhas <- linhas[linhas != ""]

  idx <- which(
    str_detect(
      linhas,
      "Amazonas|Lima|Lambayeque|Cajamarca|Piura|Tumbes|Ica|Arequipa|Cusco|La Libertad|Apurímac"
    )
  )

  if (length(idx) > 0) {

    linha <- linhas[idx[1]]

    # Não conseguimos garantir os limites apenas
    # pela linha; por isso retornamos o bloco bruto.
    return(
      tibble(
        adm1 = NA_character_,
        adm2 = NA_character_,
        adm3 = NA_character_,
        epidemiological_unit = NA_character_
      )
    )
  }

  tibble(
    adm1 = NA_character_,
    adm2 = NA_character_,
    adm3 = NA_character_,
    epidemiological_unit = NA_character_
  )
}


# ============================================================
# 9. EXTRAIR COORDENADAS
# ============================================================

extrair_coordenadas <- function(texto) {

  coord <- str_match(
    texto,
    "(-?\\d+\\.\\d+)\\s*,\\s*(-?\\d+\\.\\d+)"
  )

  tibble(
    latitude = as.numeric(coord[, 2]),
    longitude = as.numeric(coord[, 3])
  )
}


# ============================================================
# 10. EXTRAIR LOCATION
# ============================================================

extrair_location <- function(texto) {

  resultado <- str_match(
    texto,
    "LOCATION Latitude, Longitude OUTBREAKS IN CLUSTER Measuring unit\\s+(.+?)\\s+(-?\\d+\\.\\d+\\s*,\\s*-?\\d+\\.\\d+)"
  )

  tibble(
    location = str_trim(resultado[, 2])
  )
}


# ============================================================
# 11. EXTRAIR UNIDADE EPIDEMIOLÓGICA
# ============================================================

extrair_unidade <- function(texto) {

  resultado <- str_match(
    texto,
    "EPIDEMIOLOGICAL UNIT\\s+(.+?)\\s+LOCATION"
  )

  tibble(
    epidemiological_unit = str_trim(
      resultado[, 2]
    )
  )
}


# ============================================================
# 12. EXTRAIR POPULAÇÃO AFETADA
# ============================================================

extrair_populacao <- function(texto) {

  # Localiza a tabela de população

  bloco <- str_match(
    texto,
    "Species Wildlife type\\s+Susceptible Cases Deaths Killed and Disposed of Slaughtered/ Killed for commercial use Vaccinated\\s+(.+?)\\s+METHOD OF DIAGNOSTIC"
  )[, 2]

  if (is.na(bloco)) {

    return(
      tibble(
        species = NA_character_,
        bird_type = NA_character_,
        susceptible = NA_real_,
        cases = NA_real_,
        deaths = NA_real_,
        killed_disposed = NA_real_,
        slaughtered_commercial = NA_real_,
        vaccinated = NA_real_
      )
    )
  }

  # Normaliza espaços

  bloco <- str_squish(bloco)

  # Procura os números da tabela
  numeros <- str_extract_all(
    bloco,
    "(?<![A-Za-z])-?\\d+(?:[\\.,]\\d+)?"
  )[[1]]

  numeros <- map_dbl(
    numeros,
    extrair_numero
  )

  # O texto contém:
  # espécie
  # tipo
  # susceptible
  # cases
  # deaths
  # killed/disposed
  # slaughtered
  # vaccinated

  # Como os campos podem variar entre registros,
  # guardamos os valores numéricos encontrados.

  if (length(numeros) >= 7) {

    valores <- tail(
      numeros,
      7
    )

  } else {

    valores <- c(
      numeros,
      rep(
        NA_real_,
        7 - length(numeros)
      )
    )
  }

  tibble(
    species = NA_character_,
    bird_type = NA_character_,
    susceptible = valores[1],
    cases = valores[2],
    deaths = valores[3],
    killed_disposed = valores[4],
    slaughtered_commercial = valores[5],
    vaccinated = valores[6]
  )
}


# ============================================================
# 13. FUNÇÃO PRINCIPAL DE EXTRAÇÃO
# ============================================================

extrair_outbreak <- function(texto, pagina) {

  identificacao <- extrair_identificacao(
    texto
  )

  coordenadas <- extrair_coordenadas(
    texto
  )

  location <- extrair_location(
    texto
  )

  unidade <- extrair_unidade(
    texto
  )

  populacao <- extrair_populacao(
    texto
  )

  tibble(
    page = pagina
  ) %>%

    bind_cols(
      identificacao
    ) %>%

    bind_cols(
      coordenadas
    ) %>%

    bind_cols(
      location
    ) %>%

    bind_cols(
      unidade
    ) %>%

    bind_cols(
      populacao
    )
}


# ============================================================
# 14. PROCESSAR TODAS AS PÁGINAS
# ============================================================

cat("Extraindo outbreaks...\n")

dados <- map2_dfr(
  paginas_limpa,
  seq_along(paginas_limpa),
  extrair_outbreak
)


# ============================================================
# 15. REMOVER PÁGINAS SEM OUTBREAK
# ============================================================

dados <- dados %>%

  filter(
    !is.na(outbreak_id)
  )


# ============================================================
# 16. CONVERSÃO DE DATAS
# ============================================================

dados <- dados %>%

  mutate(

    year = year(start_date),

    month = month(
      start_date
    ),

    duration_days =
      as.numeric(
        end_date - start_date
      )

  )


# ============================================================
# 17. VERIFICAÇÃO
# ============================================================

cat("\n")
cat("============================================\n")
cat("RESULTADO DA EXTRAÇÃO\n")
cat("============================================\n")

cat(
  "Outbreaks encontrados:",
  nrow(dados),
  "\n"
)

cat(
  "Outbreaks com coordenadas:",
  sum(
    !is.na(dados$latitude) &
    !is.na(dados$longitude)
  ),
  "\n"
)

cat(
  "Outbreaks com data:",
  sum(
    !is.na(dados$start_date)
  ),
  "\n"
)

cat("============================================\n")


# ============================================================
# 18. EXPORTAR BASE BRUTA EXTRAÍDA
# ============================================================

write_csv(
  dados,
  "data/processed/outbreaks_extraidos.csv"
)


# ============================================================
# 19. MAPA DOS SURTOS
# ============================================================

dados_mapa <- dados %>%

  filter(
    !is.na(latitude),
    !is.na(longitude)
  )


pontos <- st_as_sf(
  dados_mapa,
  coords = c(
    "longitude",
    "latitude"
  ),
  crs = 4326
)


# ============================================================
# 20. BAIXAR MAPA DO PERU
# ============================================================

peru <- geodata::gadm(
  country = "PER",
  level = 1,
  path = "data"
)

peru <- st_as_sf(
  peru
)


# ============================================================
# 21. MAPA
# ============================================================

mapa <- ggplot() +

  geom_sf(
    data = peru,
    fill = "grey95",
    color = "grey60",
    linewidth = 0.3
  ) +

  geom_sf(
    data = pontos,
    aes(
      size = deaths,
      color = bird_type
    ),
    alpha = 0.7
  ) +

  scale_size_continuous(
    name = "Deaths",
    range = c(
      2,
      10
    )
  ) +

  labs(
    title = "Highly Pathogenic Avian Influenza Outbreaks in Peru",
    subtitle = "Spatial distribution of reported outbreaks",
    x = NULL,
    y = NULL,
    color = "Bird type"
  ) +

  theme_minimal() +

  theme(
    axis.text = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    legend.position = "right"
  )


# ============================================================
# 22. SALVAR MAPA
# ============================================================

ggsave(
  "figures/mapa_surtos_peru.png",
  mapa,
  width = 10,
  height = 8,
  dpi = 300
)


# ============================================================
# 23. MAPA DE DENSIDADE
# ============================================================

mapa_densidade <- ggplot() +

  geom_sf(
    data = peru,
    fill = "grey95",
    color = "grey70"
  ) +

  stat_density_2d(
    data = dados_mapa,
    aes(
      x = longitude,
      y = latitude,
      fill = after_stat(level)
    ),
    geom = "polygon",
    alpha = 0.5,
    bins = 10
  ) +

  geom_point(
    data = dados_mapa,
    aes(
      x = longitude,
      y = latitude
    ),
    size = 1,
    alpha = 0.5
  ) +

  scale_fill_viridis_c(
    name = "Density"
  ) +

  labs(
    title = "Spatial Density of Avian Influenza Outbreaks",
    subtitle = "Peru"
  ) +

  theme_minimal() +

  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank()
  )


ggsave(
  "figures/mapa_densidade_surtos.png",
  mapa_densidade,
  width = 10,
  height = 8,
  dpi = 300
)


# ============================================================
# 24. DISTRIBUIÇÃO TEMPORAL
# ============================================================

temporal <- dados %>%

  filter(
    !is.na(start_date)
  ) %>%

  count(
    year,
    month
  ) %>%

  mutate(
    date = as.Date(
      paste(
        year,
        month,
        "01",
        sep = "-"
      )
    )
  )


grafico_temporal <- ggplot(
  temporal,
  aes(
    x = date,
    y = n
  )
) +

  geom_line(
    linewidth = 1
  ) +

  geom_point(
    size = 2
  ) +

  scale_x_date(
    date_labels = "%m/%Y"
  ) +

  labs(
    title = "Temporal Distribution of Avian Influenza Outbreaks",
    x = "Date",
    y = "Number of outbreaks"
  ) +

  theme_minimal()


ggsave(
  "figures/evolucao_temporal.png",
  grafico_temporal,
  width = 10,
  height = 6,
  dpi = 300
)


# ============================================================
# 25. ESTATÍSTICAS BÁSICAS
# ============================================================

estatisticas <- dados %>%

  summarise(

    outbreaks = n(),

    total_susceptible =
      sum(
        susceptible,
        na.rm = TRUE
      ),

    total_cases =
      sum(
        cases,
        na.rm = TRUE
      ),

    total_deaths =
      sum(
        deaths,
        na.rm = TRUE
      ),

    total_killed =
      sum(
        killed_disposed,
        na.rm = TRUE
      ),

    total_slaughtered =
      sum(
        slaughtered_commercial,
        na.rm = TRUE
      )

  )


write_csv(
  estatisticas,
  "data/processed/estatisticas.csv"
)


# ============================================================
# 26. FINAL
# ============================================================

cat("\n")
cat("============================================\n")
cat("PROCESSAMENTO CONCLUÍDO\n")
cat("============================================\n")
cat("Base:", "data/processed/outbreaks_extraidos.csv", "\n")
cat("Mapa:", "figures/mapa_surtos_peru.png", "\n")
cat("Densidade:", "figures/mapa_densidade_surtos.png", "\n")
cat("Temporal:", "figures/evolucao_temporal.png", "\n")
cat("============================================\n")