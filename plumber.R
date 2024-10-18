library(plumber)
library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)
library(jsonlite)

#* @apiTitle Plumber Example API
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

# Carregar o banco de dados CSV (ou criar se não existir)
file_path <- "dados_regressao.csv"

if (!file.exists(file_path)) {
  write_csv(data.frame(x = numeric(), grupo = character(), y = numeric(), momento_registro = character()), file_path)
}

#* Adicionar novo registro ao banco de dados
#* @param x Valor de x
#* @param grupo Valor de grupo
#* @param y Valor de y
#* @post /inserir
function(req, res, x = NULL, grupo = NULL, y = NULL) {
  
  if (is.null(x) || is.null(grupo) || is.null(y)) {
    res$status <- 400
    return(list(error = "Parâmetros 'x', 'grupo' e 'y' são obrigatórios."))
  }
  
  x <- as.numeric(x)
  y <- as.numeric(y)
  
  if (is.na(x) || is.na(y)) {
    res$status <- 400
    return(list(error = "'x' e 'y' devem ser valores numéricos."))
  }
  
  db <- read_csv(file_path)
  
  novo_registro <- tibble(id = nrow(db) + 1, x = x, grupo = grupo, y = y, momento_registro = with_tz(now(), tzone = "America/Sao_Paulo")
  )
  
  # Adicionar o novo registro ao banco de dados
  db <- rbind(db, novo_registro)
  
  # Escrever de volta ao arquivo CSV
  write_csv(db, file_path)
  
  return(list(message = "Registro inserido com sucesso", data = novo_registro))
}


#* Atualizar um registro existente
#* @param id ID do registro a ser atualizado
#* @param x Novo valor de x (opcional)
#* @param grupo Novo valor de grupo (opcional)
#* @param y Novo valor de y (opcional)
#* @put /atualizar
function(req, res, id = NULL, x = NULL, grupo = NULL, y = NULL) {
  
  # Verificar se o parâmetro 'id' foi fornecido
  if (is.null(id)) {
    res$status <- 400
    return(list(error = "O parâmetro 'id' é obrigatório para atualizar um registro."))
  }
  
  db <- read_csv(file_path)
  id <- as.integer(id)
  registro <- db %>% filter(id == !!id)
  
  if (nrow(registro) == 0) {
    res$status <- 404
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
  
  write_csv(db, file_path)
  return(list(message = "Registro atualizado com sucesso", id = id))
}

#* Deletar um registro
#* @param id ID do registro a ser deletado
#* @delete /deletar
function(req, res, id = NULL) {
  if (is.null(id)) {
    res$status <- 400
    return(list(error = "O parâmetro 'id' é obrigatório para deletar um registro."))
  }
  
  db <- read_csv(file_path)
  id <- as.integer(id)
  if (nrow(db %>% filter(id == !!id)) == 0) {
    res$status <- 404
    return(list(error = "Registro com ID fornecido não encontrado."))
  }
  
  db <- db %>% filter(id != !!id)
  
  write_csv(db, file_path)
  return(list(message = "Registro deletado com sucesso", id = id))
}

#* Adicionar novo registro ao banco de dados
#* @get /grafico
#* @serializer png
function(req, res) {

  db <- read_csv(file_path)

  p <- ggplot(data = db, aes(x = x, y = y, colour = grupo)) +
    geom_point() + geom_smooth(method = "lm", se = FALSE) +  
    labs(title = "Gráfico com Retas de Regressão por Grupo",
         x = "Eixo X",
         y = "Eixo Y",
         colour = "Grupo") +
    theme_minimal()
  
  ggsave("grafico.png", plot = p, width = 8, height = 6, device = "png")
  
  res$setHeader("Content-Type", "image/png")  # Define o cabeçalho da resposta como imagem PNG
  return(file("grafico.png", "rb"))  # Retorna a imagem
}

#* Obter estimativas da regressão em formato JSON
#* @get /regressao
#* @serializer json
function(res) {

  db <- read_csv(file_path)
  modelo <- lm(y ~ x + grupo, data = db)
  
  resultados <- summary(modelo)$coefficients[,1]
  resutados <- toJSON(resultados, pretty = T)
  
  # Retornar os resultados em formato JSON
  return(resultados)
}

db <- read_csv(file_path)
modelo <- lm(y ~ x + grupo, data = db)

#*Residuos do modelo ajustado
#*@get /residuos
function(){
  db <- read_csv(file_path)
  modelo <- lm(y ~ x + grupo, data = db)
  residuos <- toJSON(modelo$residuals)
  return(residuos)
}


#*Gráfico dos residuos do modelo ajustado
#*@serializer png
#*@get /graficoresiduos
function() {
    coeficientes <- modelo$coefficients
    residuos <- modelo$residuals
    Y_pred <- modelo$fitted.values
    
    graficos <- list()
    
    plot(Y_pred, residuos, 
         main = "Gráfico de Resíduos vs. Ajustados", 
         xlab = "Valores Ajustados", 
         ylab = "Resíduos", 
         pch = 19, # Tipo de ponto
         col = "blue") # Cor dos pontos
  
  # Adicionar uma linha horizontal em y = 0
  abline(h = 0, lty = 2, col = "red")  # Linha horizontal tracejada
  
  hist(residuos)          #COMO RETORNAR MAIS DE UMA IMAGEM
  qqnorm(residuos)
  qqline(residuos)
  acf(residuos)
  
  # 
  # graficos$grafico_qq_res <- ggplot2::ggplot(data = data.frame(residuos), ggplot2::aes(sample = residuos)) +
  #   ggplot2::stat_qq() +
  #   ggplot2::stat_qq_line(color = "red") +
  #   ggplot2::labs(title = "Gráfico Q-Q da Normalidade dos Resíduos") +
  #   ggplot2::theme_bw()
  # 
  # 
  # acf_data <- acf(residuos, plot = FALSE, lag.max = 30)
  # acf_df <- data.frame(
  #   Lag = acf_data$lag[-1],
  #   ACF = acf_data$acf[-1]
  # )
  # 
  # 
  # n <- length(residuos)
  # ci_upper <- 1.96 / sqrt(n)
  # ci_lower <- -1.96 / sqrt(n)
  # 
  # graficos$grafico_acf_residuos <- ggplot2::ggplot(acf_df, ggplot2::aes(x = Lag, y = ACF)) +
  #   ggplot2::geom_bar(stat = "identity", fill = "blue", color = "black", width = 0.7) +
  #   ggplot2::labs(title = "Autocorrelação dos Resíduos",
  #                 x = "Lag",
  #                 y = "Autocorrelação") +
  #   ggplot2::geom_hline(yintercept = ci_upper, linetype = "dashed", color = "red") +
  #   ggplot2::geom_hline(yintercept = ci_lower, linetype = "dashed", color = "red") +
  #   ggplot2::theme_bw()
  # 
  
  return(graficos)
}

#*Significância dos coeficientes
#*@get /significancia
#*@serializer json
function(){
  # Extrair os coeficientes
  coeficientes <- summary(modelo)$coefficients
  
  # Criar um data frame com os coeficientes e seus nomes
  coeficientes_df <- data.frame(
    Estimativas = coeficientes[, 1],
    Erro_Est = coeficientes[, 2],
    Valor_t = coeficientes[, 3],
    P_valor = coeficientes[, 4],
    row.names = rownames(coeficientes),  # Nomes dos coeficientes como rownames
    stringsAsFactors = FALSE  # Para evitar fatores
  )
  
  # Converter o data frame para JSON
  resultados_json <- toJSON(coeficientes_df, pretty = T)
  
  return(resultados_json)
}

#* Realizar predições
#* @post /predicao
#* @param x Valor de x
#* @param grupo Grupo da observação
#* @serializer json
function(req, res, x, grupo) {

  if (missing(x) || missing(grupo)) {
    res$status <- 400  # Código de status para erro de requisição
    return(list(error = "Os parâmetros 'x' e 'grupo' são obrigatórios."))
  }
  
  nova_obs <- data.frame(x = as.numeric(x), grupo = as.factor(grupo))
  predicao <- predict(modelo, newdata = nova_obs)
  
  # Retornar a previsão
  return(list(predicao = predicao))
}


#* Realizar múltiplas predições
#* @param x Valores de entrada como uma lista de listas (JSON)
#* @post /predictions
#* @serializer unboxedJSON
function(x) {
  # Verifica se x é nulo ou não contém dados
  if (is.null(x) || length(x) == 0) {
    return(list(error = "Dados de entrada inválidos"))
  }
  
  # Verifica se os dados estão no formato JSON
  # Converte a entrada JSON para uma lista
  input_data <- jsonlite::fromJSON(x)
  
  # Verifica se a conversão foi bem-sucedida
  if (is.null(input_data) || nrow(input_data) == 0) {
    return(list(error = "Formato JSON inválido ou vazio"))
  }
  
  # Convertendo a lista em um dataframe
  input_data <- as.data.frame(input_data)
  
  # Realizando a predição
  predicoes <- predict(modelo, input_data)
  
  # Criar uma lista com as observações e predições
  resultado <- list()
  for (i in seq_along(predicoes)) {
    resultado[[i]] <- list(observacao = input_data[i, ], predicao = predicoes[i])
  }
  
  return(resultado)
}




