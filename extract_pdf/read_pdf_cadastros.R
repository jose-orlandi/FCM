# ============================================================
# PROJETO - EXTRAÇÃO DE DADOS DE PDF
# Ferramentas Computacionais para Modelagem
# ============================================================

# ------------------------------------------------------------
# 1. PACOTES
# ------------------------------------------------------------

pacotes <- c(
  "pdftools",
  "stringr",
  "dplyr",
  "purrr",
  "readr",
  "tibble",
  "ggplot2"
)

instalar <- pacotes[!pacotes %in% installed.packages()[, "Package"]]

if (length(instalar) > 0) {
  install.packages(instalar)
}

invisible(lapply(pacotes, library, character.only = TRUE))


# ------------------------------------------------------------
# 2. DIRETÓRIOS
# ------------------------------------------------------------

dir.create("data", showWarnings = FALSE)
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

pdf_path <- "C:\\Users\\vitor\\Documents\\Ferramentas Computacionais de Modelagem\\Projeto_FCM\\cadastro.pdf"

if (!file.exists(pdf_path)) {
  stop(
    "PDF não encontrado!\n",
    "Coloque o arquivo em: ", pdf_path
  )
}


# ------------------------------------------------------------
# 3. EXTRAÇÃO DO TEXTO DO PDF
# ------------------------------------------------------------

cat("Lendo PDF...\n")

paginas <- pdf_text(pdf_path)

texto <- paste(paginas, collapse = "\n")

# Normalização básica
texto <- str_replace_all(texto, "\r\n", "\n")
texto <- str_replace_all(texto, "\r", "\n")
texto <- str_replace_all(texto, "[ \t]+", " ")
texto <- str_replace_all(texto, "\n+", "\n")

linhas <- str_split(texto, "\n")[[1]]
linhas <- str_trim(linhas)
linhas <- linhas[linhas != ""]


# ------------------------------------------------------------
# 4. IDENTIFICAÇÃO DOS REGISTROS
# ------------------------------------------------------------

# Cada pessoa começa em uma linha "Nome:" ou "nome:"
inicio <- which(
  str_detect(
    linhas,
    regex("^nome\\s*:", ignore_case = TRUE)
  )
)

if (length(inicio) == 0) {
  stop("Nenhum registro iniciado por 'Nome:' foi encontrado.")
}

fim <- c(inicio[-1] - 1, length(linhas))

registros <- map2(
  inicio,
  fim,
  ~ paste(linhas[.x:.y], collapse = "\n")
)


# ------------------------------------------------------------
# 5. FUNÇÃO PARA EXTRAIR CAMPOS
# ------------------------------------------------------------

extrair_campo <- function(registro, padrao) {

  resultado <- str_match(
    registro,
    regex(
      padrao,
      ignore_case = TRUE,
      multiline = TRUE
    )
  )

  if (is.na(resultado[1, 2])) {
    return(NA_character_)
  }

  str_trim(resultado[1, 2])
}


# ------------------------------------------------------------
# 6. EXTRAÇÃO DOS CAMPOS
# ------------------------------------------------------------

dados <- map_dfr(registros, function(registro) {

  nome_completo <- extrair_campo(
    registro,
    "^nome\\s*:\\s*(.+)$"
  )

  # Separa nome e AKA
  nome <- nome_completo
  aka <- NA_character_

  if (!is.na(nome_completo)) {

    if (str_detect(nome_completo, regex("\\(aka", ignore_case = TRUE))) {

      nome <- str_trim(
        str_remove(
          nome_completo,
          regex("\\s*\\(aka.*$", ignore_case = TRUE)
        )
      )

      aka <- str_match(
        nome_completo,
        regex("\\(aka\\s+(.+?)\\)", ignore_case = TRUE)
      )[, 2]

    }
  }

  # Data de nascimento
  data_nascimento <- extrair_campo(
    registro,
    "^(?:data de nascimento|dt nasc)\\s*:\\s*(.+)$"
  )

  # Endereço
  endereco <- extrair_campo(
    registro,
    "^endereço\\s*:\\s*(.+?)(?=\\s+CEP\\s*:|$)"
  )

  # CEP
  cep <- extrair_campo(
    registro,
    "^CEP\\s*:\\s*([0-9\\-]+)"
  )

  # Telefone
  telefone <- extrair_campo(
    registro,
    "^(?:tel|telefone)\\s*:\\s*([0-9()\\-\\s]+)"
  )

  # CPF
  cpf <- extrair_campo(
    registro,
    "^CPF\\s*:\\s*([0-9\\.-]+)"
  )

  tibble(
    nome = nome,
    aka = aka,
    data_nascimento_original = data_nascimento,
    endereco = endereco,
    cep_original = cep,
    telefone_original = telefone,
    cpf_original = cpf
  )
})


# ------------------------------------------------------------
# 7. PADRONIZAÇÃO
# ------------------------------------------------------------

dados <- dados %>%
  mutate(

    # Remove tudo que não for número
    cpf = str_remove_all(cpf_original, "[^0-9]"),

    cep = str_remove_all(cep_original, "[^0-9]"),

    telefone = str_remove_all(telefone_original, "[^0-9]"),

    # Formatação padronizada
    cpf_formatado = if_else(
      !is.na(cpf) & nchar(cpf) == 11,
      str_c(
        substr(cpf, 1, 3), ".",
        substr(cpf, 4, 6), ".",
        substr(cpf, 7, 9), "-",
        substr(cpf, 10, 11)
      ),
      cpf
    ),

    cep_formatado = if_else(
      !is.na(cep) & nchar(cep) == 8,
      str_c(
        substr(cep, 1, 5), "-",
        substr(cep, 6, 8)
      ),
      cep
    ),

    telefone_formatado = case_when(

      !is.na(telefone) & nchar(telefone) == 11 ~
        str_c(
          "(", substr(telefone, 1, 2), ") ",
          substr(telefone, 3, 7), "-",
          substr(telefone, 8, 11)
        ),

      !is.na(telefone) & nchar(telefone) == 10 ~
        str_c(
          "(", substr(telefone, 1, 2), ") ",
          substr(telefone, 3, 6), "-",
          substr(telefone, 7, 10)
        ),

      TRUE ~ telefone
    )
  )


# ------------------------------------------------------------
# 8. RELATÓRIO DE QUALIDADE
# ------------------------------------------------------------

qualidade <- dados %>%
  summarise(
    registros = n(),

    nome_preenchido = sum(!is.na(nome)),
    aka_preenchido = sum(!is.na(aka)),
    nascimento_preenchido = sum(!is.na(data_nascimento_original)),
    endereco_preenchido = sum(!is.na(endereco)),
    cep_preenchido = sum(!is.na(cep_original)),
    telefone_preenchido = sum(!is.na(telefone_original)),
    cpf_preenchido = sum(!is.na(cpf_original))
  ) %>%
  pivot_longer(
    everything(),
    names_to = "campo",
    values_to = "quantidade"
  )

# Percentual de preenchimento
qualidade <- qualidade %>%
  mutate(
    percentual = quantidade / max(quantidade) * 100
  )


# ------------------------------------------------------------
# 9. SALVAR DADOS
# ------------------------------------------------------------

write_csv(
  dados,
  "data/processed/pessoas_padronizadas.csv"
)

write_csv(
  qualidade,
  "data/processed/qualidade_extracao.csv"
)


# ------------------------------------------------------------
# 10. GRÁFICO DE COMPLETUDE
# ------------------------------------------------------------

grafico_qualidade <- ggplot(
  qualidade,
  aes(
    x = reorder(campo, percentual),
    y = percentual
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Completude dos dados extraídos do PDF",
    x = "Campo",
    y = "Preenchimento (%)"
  ) +
  theme_minimal()

ggsave(
  "figures/qualidade_extracao.png",
  grafico_qualidade,
  width = 9,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# 11. ANÁLISE SIMPLES DOS NOMES
# ------------------------------------------------------------

dados <- dados %>%
  mutate(
    tamanho_nome = nchar(nome),
    tamanho_endereco = nchar(endereco)
  )

grafico_nomes <- ggplot(
  dados,
  aes(x = tamanho_nome)
) +
  geom_histogram(
    bins = 8
  ) +
  labs(
    title = "Distribuição do tamanho dos nomes",
    x = "Número de caracteres",
    y = "Quantidade de pessoas"
  ) +
  theme_minimal()

ggsave(
  "figures/distribuicao_nomes.png",
  grafico_nomes,
  width = 8,
  height = 5,
  dpi = 300
)


# ------------------------------------------------------------
# 12. RESULTADOS NO CONSOLE
# ------------------------------------------------------------

cat("\n============================================\n")
cat(" EXTRAÇÃO CONCLUÍDA\n")
cat("============================================\n\n")

cat("Registros encontrados:", nrow(dados), "\n\n")

print(
  dados %>%
    select(
      nome,
      aka,
      data_nascimento_original,
      endereco,
      cep_formatado,
      telefone_formatado,
      cpf_formatado
    )
)

cat("\nArquivos gerados:\n")
cat("- data/processed/pessoas_padronizadas.csv\n")
cat("- data/processed/qualidade_extracao.csv\n")
cat("- figures/qualidade_extracao.png\n")
cat("- figures/distribuicao_nomes.png\n")

cat("\nProjeto executado com sucesso!\n")