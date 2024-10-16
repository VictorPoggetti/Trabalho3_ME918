library(plumber)

#* @apiTitle Plumber Example API
#* 
library(dplyr)
library(readr)

ra <- 204384
set.seed(ra)
b0 <- runif(1, -2, 2); b1 <- runif(1, -2, 2)
bB <- 2; bC <- 3
n <- 25
x <- rpois(n, lambda = 4) + runif(n, -3, 3)
grupo <- sample(LETTERS[1:3], size = n, replace = TRUE)
y <- rnorm(n, mean = b0 + b1*x + bB*(grupo=="B") + bC*(grupo=="C"), sd = 2)
df <- data.frame(id = seq(1,length(y)), x = x, grupo = grupo, y = y,
                 momento_registro = lubridate::now())
readr::write_csv(df, file = "dados_regressao.csv")

# Carregar o banco de dados CSV (ou criar se não existir)
file_path <- "dados_regressao.csv"

if (!file.exists(file_path)) {
  # Criar um CSV vazio com os nomes das colunas
  write_csv(data.frame(x = numeric(), grupo = character(), y = numeric(), momento_registro = character()), file_path)
}

#* Adicionar novo registro ao banco de dados
#* @param x Valor de x
#* @param grupo Valor de grupo
#* @param y Valor de y
#* @post /inserir
function(req, res, x = NULL, grupo = NULL, y = NULL) {
  
  # Verificar se todos os parâmetros estão presentes
  if (is.null(x) || is.null(grupo) || is.null(y)) {
    res$status <- 400
    return(list(error = "Parâmetros 'x', 'grupo' e 'y' são obrigatórios."))
  }
  
  # Converter os parâmetros e garantir que x e y sejam numéricos
  x <- as.numeric(x)
  y <- as.numeric(y)
  
  if (is.na(x) || is.na(y)) {
    res$status <- 400
    return(list(error = "'x' e 'y' devem ser valores numéricos."))
  }
  
  # Ler o banco de dados existente
  db <- read_csv(file_path)
  
  # Criar uma nova linha
  novo_registro <- tibble(
    id = nrow(db) + 1,
    x = x,
    grupo = grupo,
    y = y,
    momento_registro = lubridate::now()
  )
  
  # Adicionar o novo registro ao banco de dados
  db <- rbind(db, novo_registro)
  
  # Escrever de volta ao arquivo CSV
  write_csv(db, file_path)
  
  return(list(message = "Registro inserido com sucesso", data = novo_registro))
}


#* Atualizar um registro existente
#* @param id ID do registro a ser atualizado
#* @param x Novo valor de x
#* @param grupo Novo valor de grupo
#* @param y Novo valor de y
#* @put /atualizar
function(req, res, id = NULL, x = NULL, grupo = NULL, y = NULL) {
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
  
  # Atualizar os campos, se forem fornecidos
  # if (!is.null(x)) db <- db %>% mutate(x = ifelse(id == !!id, as.numeric(x), x))
  # if (!is.null(grupo)) db <- db %>% mutate(grupo = ifelse(id == !!id, grupo, grupo))
  # if (!is.null(y)) db <- db %>% mutate(y = ifelse(id == !!id, as.numeric(y), y))
  
  db[db$id == id,] <- c(id, x, grupo, y)
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
  
  # Verificar se o ID existe
  id <- as.integer(id)
  if (nrow(db %>% filter(id == !!id)) == 0) {
    res$status <- 404
    return(list(error = "Registro com ID fornecido não encontrado."))
  }
  
  # Remover o registro
  db <- db %>% filter(id != !!id)
  
  write_csv(db, file_path)
  
  return(list(message = "Registro deletado com sucesso", id = id))
}

# plumber::plumb("api.R")$run(port=8000)



