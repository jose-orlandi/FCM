```r
# =========================================================
# WEB SCRAPING - OSCAR WINNING FILMS
# Scrapethissite: AJAX and Javascript
# =========================================================

# Instale os pacotes caso necessário:
# install.packages(c("rvest", "httr2", "jsonlite", "dplyr", "ggplot2"))

library(rvest)
library(httr2)
library(jsonlite)
library(dplyr)
library(ggplot2)


# =========================================================
# 1. PÁGINA PRINCIPAL
# =========================================================

url <- "https://www.scrapethissite.com/pages/ajax-javascript/"

pagina <- read_html(url)


# ------------------------------------------------------------
# 2. Extrair os links dos anos do HTML
# ------------------------------------------------------------

links <- pagina |>
  html_elements("a")

# Extrair texto e href separadamente
textos <- html_text2(links)
hrefs  <- html_attr(links, "href")

# Criar tabela com os links
anos_html <- data.frame(
  ano = textos,
  href = hrefs,
  stringsAsFactors = FALSE
)

# Manter somente os anos
anos_html <- anos_html |>
  filter(grepl("^20[0-9]{2}$", ano))

print(anos_html)

# ------------------------------------------------------------
# 3. Função para buscar os filmes via AJAX
# ------------------------------------------------------------

buscar_filmes <- function(ano) {

  url_ajax <- paste0(
    "https://www.scrapethissite.com/pages/ajax-javascript/",
    "?ajax=true&year=", ano
  )

  resposta <- request(url_ajax) |>
    req_perform()

  conteudo <- resp_body_string(resposta)

  dados <- fromJSON(conteudo)

  # Transformar em tabela
  tabela <- as.data.frame(dados)

  # Adicionar ano
  tabela$year <- ano

  return(tabela)
}

# ------------------------------------------------------------
# 4. Buscar todos os anos
# ------------------------------------------------------------

anos <- as.numeric(anos_html$ano)

filmes <- lapply(anos, buscar_filmes) |>
  bind_rows()

# ------------------------------------------------------------
# 5. Organizar a tabela
# ------------------------------------------------------------

filmes <- filmes |>
  select(
    title,
    year,
    nominations,
    awards,
    everything()
  ) |>
  mutate(
    year = as.numeric(year),
    nominations = as.numeric(nominations),
    awards = as.numeric(awards)
  )

# Visualizar
print(filmes)

# ------------------------------------------------------------
# 6. Salvar tabela completa
# ------------------------------------------------------------

dir.create("output", showWarnings = FALSE)

write.csv(
  filmes,
  "C:\\Users\\vitor\\Documents\\Ferramentas Computacionais de Modelagem\\Projeto_FCM\\output\\Oscar_filmes.csv",
  row.names = FALSE
)

# ------------------------------------------------------------
# 7. Resumo por ano
# ------------------------------------------------------------

resumo <- filmes |>
  group_by(year) |>
  summarise(
    filmes = n(),
    total_nominations = sum(nominations, na.rm = TRUE),
    total_awards = sum(awards, na.rm = TRUE),
    .groups = "drop"
  )

print(resumo)

write.csv(
  resumo,
  "C:\\Users\\vitor\\Documents\\Ferramentas Computacionais de Modelagem\\Projeto_FCM\\output\\resumo_oscar_por_ano.csv",
  row.names = FALSE
)

# ------------------------------------------------------------
# 8. Selecionar os filmes com mais indicações
# ------------------------------------------------------------

top_filmes <- filmes |>
  arrange(desc(nominations)) |>
  slice_head(n = 15) |>
  mutate(
    titulo = reorder(title, nominations)
  )

print(top_filmes)

# ------------------------------------------------------------
# 9. Gráfico
# ------------------------------------------------------------

grafico <- ggplot(
  top_filmes,
  aes(
    x = nominations,
    y = titulo,
    fill = factor(year)
  )
) +
  geom_col() +
  geom_text(
    aes(label = paste0(awards, " awards")),
    hjust = -0.1,
    size = 3.5
  ) +
  labs(
    title = "Oscar Winning Films",
    subtitle = "Top 15 films by number of nominations",
    x = "Nominations",
    y = "Film",
    fill = "Year"
  ) +
  theme_minimal(base_size = 12) +
  scale_x_continuous(
    expand = expansion(mult = c(0, 0.15))
  )

print(grafico)

# ------------------------------------------------------------
# 10. Salvar gráfico
# ------------------------------------------------------------

ggsave(
  "C:\\Users\\vitor\\Documents\\Ferramentas Computacionais de Modelagem\\Projeto_FCM\\output\\oscar_top15_nominations.png",
  grafico,
  width = 10,
  height = 7,
  dpi = 300
)

ggsave(
  "C:\\Users\\vitor\\Documents\\Ferramentas Computacionais de Modelagem\\Projeto_FCM\\output\\oscar_top15_nominations.pdf",
  grafico,
  width = 10,
  height = 7
)

cat("\nScraping concluído!\n")
cat("Filmes coletados:", nrow(filmes), "\n")
```
