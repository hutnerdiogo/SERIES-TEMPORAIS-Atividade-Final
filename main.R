library(readxl)
library(zoo)
library(lubridate)
library(ggplot2)
library(tseries)
library(magick)
library(gridExtra)
library(ggfortify)
library(stats)
library(forecast)
library(vars)
library(lmtest)
library(stargazer)
library(urca)


dados_cointegracao <- read_excel("dados sobre cointegracao.xlsx", sheet = 1)
dados_cointegracao$trim <- as.yearqtr(dados_cointegracao$trim, format = "%Yq%q")
dados_cointegracao

dados_sarima <- read_excel("Dados para replicar SARIMA  Vendas de Automoveis USA.xlsx", sheet = 1)
colnames(dados_sarima) <- c("trim","RCAR6T")
dados_sarima$trim <- as.Date(dados_sarima$trim)
dados_sarima

dados_var <- read_excel("Dados exemplo Modelo VAR sobre vendas veiculos e juros.xlsx", sheet=1)
dados_var$txj <- as.numeric(dados_var$txj)
colnames(dados_var) <- c("trim","vv","txj")
dados_var$trim <- ymd(paste0(dados_var$trim, "01"))

## Codigo

set.seed(99741)
cor_linha = "#971999"
folder = "Igor"
fake_sarima_dados = "dadosSarima"
fake_var_dados = "dadosVar"

# Plotar o Sarima
grafico_sar_inicial <- ggplot(dados_sarima, aes(x = trim, y = RCAR6T)) +
  geom_line(color = cor_linha) +
  labs(x = "Ano", y = "Automoveis Vendidos", title = "Gráfico SARIMA")
write.csv2(dados_sarima, file =paste0(folder,"/SAR_dados_basicos.csv"))
ggsave(paste0(folder,"/SAR.png"), plot = grafico_sar_inicial, width = 6, height = 4, dpi = 300)

grafico_sar_inicial

#Teste adfFuller
results_adf_sar <- adf.test(dados_sarima$RCAR6T)
# alterar segunda linha, onde ta escrito data:
output <- paste0("\tAugmented Dickey-Fuller Test\n\n",
                "data: ", fake_sarima_dados, "$RCAR6T\n",
                "Dickey-Fuller = ", sprintf("%.4f", results_adf_sar$statistic), ",",
                " Lag order = ","5" , ",",
                " p-value = ", sprintf("%.5f", results_adf_sar$p.value), "\n",
                "alternative hypothesis: stationary")
writeLines(output, paste0(folder, "/SAR_ADF.txt"))

# Calcular e plotar o ACF
acf_result <- acf(dados_sarima$RCAR6T, lag=50)
plot(acf_result, main = "Autocorrelation Function (ACF)", col = cor_linha)
file <- paste0(folder,"/SAR_ACF.jpg")
dev.print(png, file,width = 600, height = 400)
write.csv2(as.data.frame(acf_result$acf), file =paste0(folder,"/SAR_acf_dados.csv"))

#Plotar pacf
acf_result <- pacf(dados_sarima$RCAR6T, lag=50)
plot(acf_result, main = "Parcial Autocorrelation Function (PACF)", col = cor_linha)
file <- paste0(folder,"/SAR_PACF.jpg")
dev.print(png, file,width = 600, height = 400)
write.csv2(as.data.frame(acf_result$acf), file =paste0(folder,"/SAR_pacf_dados.csv"))
# Sarima
modelo_sarima <- Arima(dados_sarima$RCAR6T, order = c(1, 0, 0), seasonal = list(order = c(1, 0, 0), period = 12))

# Sumário do modelo
objeto_summary <- capture.output(summary(modelo_sarima))

# Remover a primeira linha e substituí-la por uma linha personalizada
  novo_summary <- c(paste0("Series: ", fake_sarima_dados ,"$RCAR6T"),objeto_summary[-1])

# Imprimir o novo summary
writeLines(novo_summary, paste0(folder, "/SAR_Summary.txt"))

## VAR

# Plotar o VAR VV
grafico_var_inicial_vv <- ggplot(dados_var, aes(x = trim, y = vv)) +
  geom_line(color = cor_linha) +
  labs(x = "Ano", y = "Automoveis Vendidos", title = "Venda de Veiculos")

grafico_var_inicial_vv
ggsave(paste0(folder,"/VAR_vv.png"), plot = grafico_var_inicial_vv, width = 6, height = 4, dpi = 300)
write.csv2(as.data.frame(dados_var), file =paste0(folder,"/VAR_vv_txj_dados.csv"))
# Plotar o VAR TXJ
grafico_var_inicial_vv <- ggplot(dados_var, aes(x = trim, y = txj)) +
  geom_line(color = cor_linha) +
  labs(x = "Ano", y = "Taxa de Juros", title = "Taxa de Juros")

grafico_var_inicial_vv
ggsave(paste0(folder,"/VAR_txj.png"), plot = grafico_var_inicial_vv, width = 6, height = 4, dpi = 300)

# adf

#Teste adfFuller VV
results_adf_var_vv <- adf.test(dados_var$vv)
# alterar segunda linha, onde ta escrito data:
output <- paste0("\tAugmented Dickey-Fuller Test\n\n",
                 "data: ", fake_var_dados, "$vv\n",
                 "Dickey-Fuller = ", sprintf("%.4f", results_adf_var_vv$statistic), ",",
                 " Lag order = ","5" , ",",
                 " p-value = ", sprintf("%.5f", results_adf_var_vv$p.value), "\n",
                 "alternative hypothesis: stationary")
writeLines(output, paste0(folder, "/VAR_vv_adf.txt"))

#Teste adfFuller VV
results_adf_var_txj <- adf.test(dados_var$txj)
# alterar segunda linha, onde ta escrito data:
output <- paste0("\tAugmented Dickey-Fuller Test\n\n",
                 "data: ", fake_var_dados, "$txj\n",
                 "Dickey-Fuller = ", sprintf("%.4f", results_adf_var_txj$statistic), ",",
                 " Lag order = ","5" , ",",
                 " p-value = ", sprintf("%.5f", results_adf_var_txj$p.value), "\n",
                 "alternative hypothesis: stationary")
writeLines(output, paste0(folder, "/VAR_txj_adf.txt"))
# montando var
modelo_var <- VAR(dados_var[,c("txj",'vv')], p = 1)
summary_var <- capture.output(summary(modelo_var))
summary_var[11] <- paste0("VAR(y = ",dados_var, "[, c(\"txj\", \"vv\")], p = 1)")
writeLines(summary_var, paste0(folder, "/VAR_summary.txt"))
# Causalidade de granger

result <-  capture.output(grangertest(txj ~ vv, data = dados_var))
result2 <-  capture.output(grangertest(vv ~ txj, data = dados_var))
writeLines(c(result,"\n", result2), paste0(folder, "/VAR_granger.txt"))
irf_txj <- irf(modelo_var,impulse = "txj", response=c("txj","vv"), n.ahead = 10)

dados_irf_txj <- data.frame(
  txj = irf_txj$irf$txj[, 'txj'],
  vv = irf_txj$irf$txj[, 'vv'],
  lower_txj = irf_txj$Lower$txj[, 'txj'],
  upper_txj = irf_txj$Upper$txj[, 'txj'],
  lower_vv = irf_txj$Lower$txj[, 'vv'],
  upper_vv = irf_txj$Upper$txj[, 'vv']
)

grafico_irf_txj_txj <- ggplot(dados_irf_txj, aes(x = seq_along(txj))) +
  geom_line(aes(y = txj, color = "Resposta ao Impulso"), size = 1) +
  geom_line(aes(y = lower_txj, color = "Limite Inferior"), linetype = "dashed", color = "red") +
  geom_line(aes(y = upper_txj, color = "Limite Superior"), linetype = "dashed", color = "red") +
  scale_color_manual(values = c("Impulse Response" = cor_linha, "Lower Bound" = "red", "Upper Bound" = "red")) +
  labs(x = "Lag", y = "Taxa Juros", title = "Impulse Response Function") +
  theme_minimal()

ggsave(paste0(folder,"/VAR_FRI_txj_txj.png"), plot = grafico_irf_txj_txj, width = 6, height = 4, dpi = 300)

grafico_irf_txj_vv <- ggplot(dados_irf_txj, aes(x = seq_along(txj))) +
  geom_line(aes(y = vv, color = "Resposta ao Impulso"), size = 1) +
  geom_line(aes(y = lower_vv, color = "Limite Inferior"), linetype = "dashed", color = "red") +
  geom_line(aes(y = upper_vv, color = "Limite Superior"), linetype = "dashed", color = "red") +
  scale_color_manual(values = c("Impulse Response" = cor_linha, "Lower Bound" = "red", "Upper Bound" = "red")) +
  labs(x = "Lag", y = "Venda de Carros", title = "Impulse Response Function") +
  theme_minimal()

ggsave(paste0(folder,"/VAR_FRI_txj_vv.png"), plot = grafico_irf_txj_vv, width = 6, height = 4, dpi = 300)

irf_vv <- irf(modelo_var,impulse = "vv", response=c("txj","vv"), n.ahead = 10)

dados_irf_vv <- data.frame(
  txj = irf_vv$irf$vv[, 'txj'],
  vv = irf_vv$irf$vv[, 'vv'],
  lower_txj = irf_vv$Lower$vv[, 'txj'],
  upper_txj = irf_vv$Upper$vv[, 'txj'],
  lower_vv = irf_vv$Lower$vv[, 'vv'],
  upper_vv = irf_vv$Upper$vv[, 'vv']
)

grafico_irf_vv_txj <- ggplot(dados_irf_vv, aes(x = seq_along(txj))) +
  geom_line(aes(y = txj, color = "Resposta ao Impulso"), size = 1) +
  geom_line(aes(y = lower_txj, color = "Limite Inferior"), linetype = "dashed", color = "red") +
  geom_line(aes(y = upper_txj, color = "Limite Superior"), linetype = "dashed", color = "red") +
  scale_color_manual(values = c("Impulse Response" = cor_linha, "Lower Bound" = "red", "Upper Bound" = "red")) +
  labs(x = "Lag", y = "Taxa Juros", title = "Impulse Response Function") +
  theme_minimal()

ggsave(paste0(folder,"/VAR_FRI_vv_txj.png"), plot = grafico_irf_vv_txj, width = 6, height = 4, dpi = 300)

grafico_irf_vv_txj <- ggplot(dados_irf_vv, aes(x = seq_along(txj))) +
  geom_line(aes(y = vv, color = "Resposta ao Impulso"), size = 1) +
  geom_line(aes(y = lower_vv, color = "Limite Inferior"), linetype = "dashed", color = "red") +
  geom_line(aes(y = upper_vv, color = "Limite Superior"), linetype = "dashed", color = "red") +
  scale_color_manual(values = c("Impulse Response" = cor_linha, "Lower Bound" = "red", "Upper Bound" = "red")) +
  labs(x = "Lag", y = "Venda de Carros", title = "Impulse Response Function") +
  theme_minimal()

ggsave(paste0(folder,"/VAR_FRI_vv_vv.png"), plot = grafico_irf_txj_vv, width = 6, height = 4, dpi = 300)

write.csv2(dados_irf_vv, file =paste0(folder,"/VAR_FRI_impulso_no_vv.csv"))
write.csv2(dados_irf_txj, file =paste0(folder,"/VAR_FRI_impulso_no_txj.csv"))

## Questão Cointegração
dados_dif_cointegracao <- cbind(diff(dados_cointegracao$c), diff(dados_cointegracao$y))
colnames(dados_dif_cointegracao) <- c("c","y")
rownames(dados_dif_cointegracao) <- dados_cointegracao$trim[-1]
df_dados_dif_cointegracao <- fortify(dados_dif_cointegracao)

grafico_var_inicial_vv <- ggplot(df_dados_dif_cointegracao, aes(x = index(dados_dif_cointegracao), y = c)) +
  geom_line(color = cor_linha) +
  labs(x = "Ano", y = "Diff Consumo Norte Americano", title = "Consumo Norte Americano")

grafico_var_inicial_vv
ggsave(paste0(folder,"/COI_consumo.png"), plot = grafico_var_inicial_vv, width = 6, height = 4, dpi = 300)
write.csv2(as.data.frame(df_dados_dif_cointegracao), file =paste0(folder,"/COI_diff_c_e_y.csv"))

grafico_var_inicial_vv <- ggplot(df_dados_dif_cointegracao, aes(x = index(dados_dif_cointegracao), y = y)) +
  geom_line(color = cor_linha) +
  labs(x = "Ano", y = "Diff PIB Norte Americano", title = "PIB Norte Americano")

ggsave(paste0(folder,"/COI_pib.png"), plot = grafico_var_inicial_vv, width = 6, height = 4, dpi = 300)

modelo_cointegracao <- lm(y ~ c, data = as.data.frame(dados_dif_cointegracao))

output <- capture.output(summary(modelo_cointegracao))
writeLines(output, paste0(folder, "/COI_summary.txt"))

residuos <- fortify(as.data.frame(residuals(modelo_cointegracao)))
colnames(residuos) <- c('res')
rownames(residuos) <- dados_cointegracao$trim[-1]
typeof(residuos)

# Plotar o gráfico dos resíduos
grafico_resi <- ggplot(residuos, aes(x = rownames(residuos), y = res)) +
  geom_point(color = cor_linha) +
  labs(x = "Ano", y = "Resíduo", title = "Resíduos")
write.csv2(as.data.frame(residuos), file =paste0(folder,"/COI_residuos_pro_vec.csv"))

# Exibir o gráfico
grafico_resi

ggsave(paste0(folder,"/COI_resid.png"), plot = grafico_resi, width = 6, height = 4, dpi = 300)

teste <- capture.output(adf.test(residuos$res))

# alterar segunda linha, onde ta escrito data:

writeLines(teste, paste0(folder, "/COI_res_ADF.txt"))

# modelo vec
vec_results <- ca.jo(df_dados_dif_cointegracao, type = "eigen", K=2)
vec_results_string <- capture.output(summary(vec_results))
writeLines(vec_results_string, paste0(folder, "/VEC_results.txt"))

