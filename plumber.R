rm(list = ls())

library(plumber)
library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)
library(jsonlite)

#* @apiTitle API para Ajustar Modelo de Regressão 
#* @apiDescription Esta API  permite manipular dados de regressão linear, realizar previsões, gerar gráficos e realizar operações como criar, atualizar, deletar um banco de dados em formato CSV.

ra <- 204384
set.seed(ra)
b0 <- runif(1, -2, 2); b1 <- runif(1, -2, 2)
bB <- 2; bC <- 3
n <- 25
x <- rpois(n, lambda = 4) + runif(n, -3, 3)
grupo <- sample(LETTERS[1:3], size = n, replace = TRUE)
y <- rnorm(n, mean = b0 + b1*x + bB*(grupo=="B") + bC*(grupo=="C"), sd = 2)
db <- data.frame(id = seq(1,length(y)), x = x, grupo = grupo, y = y,
                 momento_registro = now())
readr::write_csv(db, file = "dados_regressao.csv")

file_path <- "dados_regressao.csv"

#* Adicionar novo registro ao banco de dados
#* @param x Valor de x (numérico)
#* @param grupo Grupo ao qual pertence
#* @param y Valor de y (numérico)
#* @post /inserir
function(x = NULL, grupo = NULL, y = NULL) {
  
  if (is.null(x) || is.null(grupo) || is.null(y)) {
    return(list(error = "Parâmetros 'x', 'grupo' e 'y' são obrigatórios."))
  }
  
  x <- as.numeric(x)
  y <- as.numeric(y)
  
  if (is.na(x) || is.na(y)) {
    return(list(error = "'x' e 'y' devem ser valores numéricos."))
  }
  
  db <- read_csv(file_path)

  novo_registro <- tibble(id = nrow(db) + 1, x = x, grupo = grupo, y = y, momento_registro = lubridate::now())
  write.table(novo_registro, file = file_path, sep = ",", col.names = FALSE, 
              row.names = FALSE, append = TRUE, quote = TRUE)
  
  return(list(message = "Registro inserido com sucesso", data = novo_registro))
}

#* Atualizar um registro existente
#* @param id ID do registro a ser atualizado
#* @param x Novo valor de x
#* @param grupo Novo valor do grupo ao qual pertence
#* @param y Novo valor de y
#* @put /atualizar
function(id = NULL, x = NULL, grupo = NULL, y = NULL) {
  if (is.null(id)) {
    return(list(error = "O parâmetro 'id' é obrigatório para atualizar um registro."))
  }

  db <- read_csv(file_path)
  id <- as.integer(id)
  registro <- db %>% filter(id == !!id)
  
  if (nrow(registro) == 0) {
    return(list(error = "Registro com ID fornecido não encontrado."))
  }
  
  if (!is.null(x)) {
    db[db$id == id, "x"] <- as.numeric(x)
  }
  if (!is.null(grupo)) {
    db[db$id == id, "grupo"] <- grupo
  }
  if (!is.null(y)) {
    db[db$id == id, "y"] <- as.numeric(y)
    db[db$id == id, 'momento_registro'] <- lubridate::now()
  }
  
  write_csv(db, file_path)
  return(list(message = "Registro atualizado com sucesso", id = id))
}

#* Deletar um registro
#* @param id ID do registro a ser deletado
#* @delete /deletar
function(id = NULL) {
  if (is.null(id)) {
    return(list(error = "O parâmetro 'id' é obrigatório para deletar um registro."))
  }
  
  id <- as.integer(id)
  db <- read_csv(file_path)
  if (nrow(db %>% filter(id == !!id)) == 0) {
    return(list(error = "Registro com ID fornecido não encontrado."))
  }
  
  db <- db %>% filter(id != !!id)
  
  write_csv(db, file_path)
  return(list(message = "Registro deletado com sucesso", id = id))
}

#* Grafico de valores observados em cada grupo
#* @get /grafico 
#* @serializer png
function(req) {
  
  p <- ggplot(data = db, aes(x = x, y = y, colour = grupo)) +
    geom_point() + geom_smooth(method = "lm", se = FALSE) +  
    labs(title = "Gráfico com Retas de Regressão por Grupo",
         x = "Eixo X",
         y = "Eixo Y",
         colour = "Grupo") +
    theme_minimal()
  
  print(p)
}

#* Ajustar o modelo de regressão linear e obter estimativas
#* @get /ajustar_regressao
#* @serializer json
function() {
  modelo <<- lm(y ~ x + grupo, data = db) #salva globalmente o modelo
  
  resultados <- summary(modelo)$coefficients[,1]
  resultados <- as.list(resultados)
  resultados <- toJSON(resultados)
  
  return(resultados)
}

#* Residuos do modelo ajustado
#* @get /residuos
#* @serializer json
function() {
  if (!exists("modelo")) {
    return(list(error = "Modelo não ajustado. Use a rota /ajustar_regressao primeiro."))
  }
  
  residuos <- modelo$residuals
  return(toJSON(residuos))
}

#*Gráfico dos residuos do modelo ajustado
#*@serializer png
#*@get /grafico_residuos
function() {
  if (!exists("modelo")) {
    return(list(error = "Modelo não ajustado. Use a rota /ajustar_regressao primeiro."))
  }
  
  layout(matrix(1:4, nrow = 2, ncol = 2))  
  residuos <- modelo$residuals
  Y_pred <- modelo$fitted.values
  
  plot(Y_pred, residuos, xlab = "Valores Ajustados", ylab = "Resíduos", pch = 19, col = "blue")
  abline(h = 0, lty = 2, col = "red")  
  
  hist(residuos, main = "", ylab = "Frequência")       
  qqnorm(residuos, main = "", xlab = "Quantil Teórico", ylab = "Quantil Amostral" )
  qqline(residuos)
  acf(residuos, main = "")
}

#*Significância dos coeficientes
#*@get /significancia
#*@serializer json
function(){
  if (!exists("modelo")) {
    return(list(error = "Modelo não ajustado. Use a rota /ajustar_regressao primeiro."))
  }
  
  coeficientes <- summary(modelo)$coefficients
  
  coeficientes_df <- data.frame(Coeficiente = rownames(coeficientes),
    Estimativa = coeficientes[, 1],
    Erro_Padrao = coeficientes[, 2],
    valor_t = coeficientes[, 3],
    p_valor = coeficientes[, 4],
    stringsAsFactors = FALSE 
  )
  
  resultados_json <- toJSON(coeficientes_df)
  
  return(resultados_json)
}

#* Realizar predição
#* @get /predicao
#* @param new Valores de entrada no formato JSON
#* @serializer json
function(new) {
  
  if(is.null(new) || length(new) == 0){
    return(list(error = "Dados de entrada inválidos"))
  }
  
  if (!exists("modelo")) {
    return(list(error = "Modelo não ajustado. Use a rota /ajustar_regressao primeiro."))
  }
  
  input_data <- fromJSON(new)
  
  if (is.null(input_data) || nrow(input_data) == 0){
    return(list(error = "Formato JSON inválido ou vazio"))
  }
  predicoes <- predict(modelo, input_data)

  return(predicoes)
}



