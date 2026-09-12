# Projeto FCM

Este repositório reúne os principais materiais desenvolvidos na disciplina de Ferramentas Computacionais para Modelagem, com foco em processamento de dados, extração de informações a partir de PDFs e análise exploratória em R.

## Visão geral

O projeto contempla atividades de:

- limpeza e padronização de bases de dados;
- extração textual de documentos em PDF;
- organização de dados processados em formatos estruturados;
- análise estatística e visualização em R;
- apoio à reprodução de experimentos e relatórios da disciplina.

---

## Estrutura do repositório

```text
Projeto_FCM/
├── README.md
├── Pokemon_full.csv
├── cadastro.pdf
├── Peru - Evento 4732.pdf
├── teste.R
├── teste.txt
├── extract_pdf/
│   ├── read_pdf_cadastros.R
│   ├── read_pdf_peru.R
│   └── data/
│       ├── gadm/
│       │   └── gadm41_PER_1_pk.rds
│       ├── processed/
│       │   ├── estatisticas.csv
│       │   ├── outbreaks_extraidos.csv
│       │   ├── pessoas_padronizadas.csv
│       │   └── qualidade_extracao.csv
│       └── raw/
├── output/
└── .git/
```

---

## Principais arquivos

### 1. Base de dados e scripts gerais

- `Pokemon_full.csv`: conjunto de dados de Pokémon utilizado em exercícios de modelagem e clustering.
- `teste.R`: script de apoio para testes e experimentos em R.
- `teste.txt`: arquivo complementar de referência.

### 2. Extração de dados em PDF

A pasta `extract_pdf/` contém os principais scripts do projeto:

- `read_pdf_cadastros.R`: extração e padronização de registros de cadastros pessoais.
- `read_pdf_peru.R`: processamento de dados epidemiológicos relacionados ao Peru, incluindo limpeza e análise espacial.

Os resultados intermediários e processados são armazenados em:

- `extract_pdf/data/processed/pessoas_padronizadas.csv`
- `extract_pdf/data/processed/qualidade_extracao.csv`
- `extract_pdf/data/processed/estatisticas.csv`
- `extract_pdf/data/processed/outbreaks_extraidos.csv`

---

## Objetivos do projeto

O repositório foi organizado para demonstrar e praticar:

- leitura de dados em diferentes formatos;
- normalização e validação de registros;
- extração de texto a partir de PDFs;
- manipulação e organização de dados em R;
- geração de arquivos estruturados para análise posterior;
- apoio à documentação e reprodução de resultados acadêmicos.

---

## Tecnologias utilizadas

Os scripts foram desenvolvidos principalmente em R, com uso de pacotes como:

- `dplyr` para manipulação de dados;
- `stringr` para limpeza e tratamento de strings;
- `readr` para leitura de arquivos tabulares;
- `pdftools` para extração de texto de PDF;
- `ggplot2` para visualização de resultados;
- `sf` e `geodata` para análise espacial e geoprocessamento.

---

## Como executar

1. Certifique-se de que o R e os pacotes necessários estejam instalados.
2. Acesse o script desejado, como `teste.R` ou os arquivos dentro de `extract_pdf/`.
3. Ajuste os caminhos locais dos arquivos, caso necessário.
4. Execute o código em sequência para gerar os outputs em `extract_pdf/data/processed/` e em `output/`.

---

## Observação

Este repositório representa um ambiente acadêmico de desenvolvimento e experimentação. Ele contém arquivos de estudo, scripts em andamento e dados processados usados como suporte para análise e documentação do curso.

---

## Licença e uso

O conteúdo deste repositório é destinado a fins acadêmicos e de estudo. A reprodução ou reutilização deve respeitar o contexto didático e os materiais originais utilizados na disciplina.
