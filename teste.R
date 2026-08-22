# Exemplo de gráfico em R
# Se necessário, instale o pacote:
# install.packages("ggplot2")

library(ggplot2)

# Dados de exemplo
dados <- data.frame(
    mes = factor(month.abb[1:6], levels = month.abb[1:6]),
    temperatura = c(20, 22, 25, 28, 26, 23)
)

# teste chato 
S
# Gráfico de linha
ggplot(dados, aes(x = mes, y = temperatura, group = 1)) +
    geom_line(color = "steelblue", linewidth = 1.2) +
    geom_point(size = 3, color = "darkred") +
    labs(
        title = "Temperatura ao longo dos meses",
        x = "Mês",
        y = "Temperatura (°C)"
    ) +
    theme_minimal()