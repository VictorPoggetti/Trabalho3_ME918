library(plumber)
library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)
library(jsonlite)

#* @apiTitle API para Ajustar Modelo de Regressão 
#* 

ra <- 204384
set.seed(ra)
b0 <- runif(1, -2, 2); b1 <- runif(1, -2, 2)
bB <- 2; bC <- 3
n <- 25
x <- rpois(n, lambda = 4) + runif(n, -3, 3)
grupo <- sample(LETTERS[1:3], size = n, replace = TRUE)
y <- rnorm(n, mean = b0 + b1*x + bB*(grupo=="B") + bC*(grupo=="C"), sd = 2)
df <- data.frame(id = seq(1,length(y)), x = x, grupo = grupo, y = y,
                 momento_registro = with_tz(now(), tzone = "America/Sao_Paulo"))
readr::write_csv(df, file = "dados_regressao.csv")

file_path <- "dados_regressao.csv"
db <- read_csv(file_path)

#* Adicionar novo registro ao banco de dados
#* @param x Valor de x
#* @param grupo Valor de grupo
#* @param y Valor de y
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
  novo_registro <- tibble(id = nrow(db) + 1, x = x, grupo = grupo, y = y, momento_registro = with_tz(now(), tzone = "America/Sao_Paulo")
  )
  
  # Adicionar o novo registro ao banco de dados
  db <- rbind(db, novo_registro)
  
  return(list(message = "Registro inserido com sucesso", data = novo_registro))
}

#* Atualizar um registro existente
#* @param id ID do registro a ser atualizado
#* @param x Novo valor de x (opcional)
#* @param grupo Novo valor de grupo (opcional)
#* @param y Novo valor de y (opcional)
#* @put /atualizar
function(req, res, id = NULL, x = NULL, grupo = NULL, y = NULL) {
  
  if (is.null(id)) {
    return(list(error = "O parâmetro 'id' é obrigatório para atualizar um registro."))
  }
  
  
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
  }
  
  return(list(message = "Registro atualizado com sucesso", id = id))
}

#* Deletar um registro
#* @param id ID do registro a ser deletado
#* @delete /deletar
function(req, res, id = NULL) {
  if (is.null(id)) {
    return(list(error = "O parâmetro 'id' é obrigatório para deletar um registro."))
  }
  
  id <- as.integer(id)
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

#* Ajustar o modelo e obter estimativas da regressão em formato JSON
#* @get /ajuste_regressao
#* @serializer json
function() {
  modelo <- lm(y ~ x + grupo, data = db)
  
  resultados <- summary(modelo)$coefficients[,1]
  resultados <- as.list(resultados)
  resultados <- toJSON(resultados)
  
  return(resultados)
}

#*Residuos do modelo ajustado
#*@get /residuos
function(){
  modelo <- lm(y ~ x + grupo, data = db)
  residuos <- toJSON(modelo$residuals)
  return(residuos)
}

#*Gráfico dos residuos do modelo ajustado
#*@serializer png
#*@get /grafico residuos
function() {
  layout(matrix(1:4, nrow = 2, ncol = 2))  
  residuos <- modelo$residuals
  Y_pred <- modelo$fitted.values
  
  plot(Y_pred, residuos, xlab = "Valores Ajustados", ylab = "Resíduos", 
       pch = 19, ,col = "blue")
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
  coeficientes <- summary(modelo)$coefficients
  
  coeficientes_df <- data.frame(
    Estimativas = coeficientes[, 1],
    Erro_Est = coeficientes[, 2],
    Valor_t = coeficientes[, 3],
    P_valor = coeficientes[, 4],
    row.names = rownames(coeficientes), 
    stringsAsFactors = FALSE 
  )
  
  resultados_json <- toJSON(coeficientes_df)
  
  return(resultados_json)
}

#* Realizar predição
#* @post /predicao
#* @param x Valor de x
#* @param grupo Grupo da observação
#* @serializer json
function(req, res, x, grupo) {
  if (missing(x) || missing(grupo)) {
    return(list(error = "Os parâmetros 'x' e 'grupo' são obrigatórios."))
  }
  
  nova_obs <- data.frame(x = as.numeric(x), grupo = as.factor(grupo))
  predicao <- predict(modelo, newdata = nova_obs)
  
  return(list(predicao = predicao))
}


#* Realizar múltiplas predições
#* @param x Valores de entrada como uma lista de listas (JSON)
#* @post /predições
#* @serializer unboxedJSON
function(x) {
  if (is.null(x) || length(x) == 0) {
    return(list(error = "Dados de entrada inválidos"))
  }
  
  input_data <- jsonlite::fromJSON(x)
  
  if (is.null(input_data) || nrow(input_data) == 0) {
    return(list(error = "Formato JSON inválido ou vazio"))
  }
  
  input_data <- as.data.frame(input_data)
  
  predicoes <- predict(modelo, input_data)
  
  resultado <- list()
  for (i in seq_along(predicoes)) {
    resultado[[i]] <- list(observacao = input_data[i, ], predicao = predicoes[i])
  }
  
  return(resultado)
}


