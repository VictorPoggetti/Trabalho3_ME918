
# API para Ajustar Modelo de Regressão

Este projeto cria uma API que interage com um conjunto de dados simulado
para realizar regressão linear, além de fazer previsões baseadas no
modelo ajustado.

## Funcionalidades da API

Esta API, construída com **plumber** em R, permite:

- Manipulação de dados para regressão linear.
- Realização de previsões e geração de gráficos.
- Operações CRUD (Criar, Ler, Atualizar, Deletar) em um banco de dados
  CSV.
- Ajuste de um modelo de regressão linear e análise de resíduos e
  significância dos coeficientes.

### Requisitos de Instalação

Para executar a API, você precisará dos seguintes pacotes R:

``` r
install.packages(c("plumber", "dplyr", "readr", "ggplot2", "jsonlite", "lubridate"))
```

### Iniciando a API

Após clonar este repositório, inicie o servidor da API com o seguinte
código:

``` r
library(plumber)

# Carregar o arquivo de rotas
pr <- plumber::plumb("plumber.R")

# Iniciar a API na porta 8000
pr$run(port = 8000)
```

## Exemplos

### /inserir

Insere uma nova observação com os parâmetros `x` (numérico), `grupo`, e
`y` (numérico) no banco de dados. A data e hora da inserção, assim como
um ID exclusivo, são registrados automaticamente.

**Parâmetros:**  
- `x`: Valor numérico da variável x.  
- `grupo`: Grupo a que a observação pertence.  
- `y`: Valor numérico da variável y.

**Exemplo de requisição:**

``` bash
curl -X 'POST' \
  'http://127.0.0.1:8000/inserir?x=2.4&grupo=B&y=7' \
  -H 'accept: */*'
```

### /atualizar

Atualiza os valores de um registro existente no banco de dados.

**Parâmetros:**  
- `id`: O ID do registro que será atualizado.  
- `x`: Novo valor numérico para a variável x.  
- `grupo`: Novo valor para o grupo.  
- `y`: Novo valor numérico para a variável y.

**Exemplo de requisição:**

``` bash
curl -X 'PUT' \
  'http://127.0.0.1:8000/atualizar?id=3&x=5&grupo=C&y=9' \
  -H 'accept: */*'
```

### /deletar

Deleta o registro do ID informado.

**Parâmetros:**  
- `id`: O ID do registro que será deletado.

**Exemplo de Requisição**

``` bash
curl -X 'DELETE' \
  'http://127.0.0.1:4570/deletar?id=2' \
  -H 'accept: */*'
```

### /grafico

Retorna um gráfico de dispersão dos valores observados com retas de
regressão em cada grupo no conjunto de dados atual.

**Exemplo de Requisição**

``` bash
curl -X 'GET' \
  'http://127.0.0.1:4570/grafico' \
  -H 'accept: image/png'
```

### /ajustar_regressão

Ajusta o modelo de regressão (possuindo variável resposta y) e retorna
as estimativas dos coeficientes da regressão em formato JSON. Utiliza as
observações contidas no atual conjunto de dados.

**Exemplo de Requisição**

``` bash
curl -X 'GET' \
  'http://127.0.0.1:4570/ajustar_regressao' \
  -H 'accept: application/json'
```

### /residuos

Retorna os resíduos do modelo ajustado na rota “ajustar_regressão” em
formato JSON.

**Exemplo de Requisição**

``` bash
curl -X 'GET' \
  'http://127.0.0.1:4570/residuos' \
  -H 'accept: application/json'
```

### /grafico_residuos

Retorna gráficos para diagnóstico dos resíduos, como o gráfico de
autocorrelação, histograma, QQ-Norm dos resíduos e o um gráico de pontos
do resíduos x observação.

**Exemplo de Requisição**

``` bash
curl -X 'GET' \
  'http://127.0.0.1:4570/grafico_residuos' \
  -H 'accept: image/png'
```

### /significancia

Retorna o resultado do teste t realizado em cada coeficiente do modelo
de regressão ajustado.

**Exemplo de Requisição**

``` bash
curl -X 'GET' \
  'http://127.0.0.1:4570/significancia' \
  -H 'accept: application/json'
```

### /predicao

Realiza previsões de `y` com base nos pares `x` e `grupo` fornecidos no
formato JSON. Os valores preditos de `y` são retornados em formato JSON.

**Parâmetro:**  
- `new`: Lista em formato JSON contendo os valores de `x`(numérico) e
`grupo` para os quais a predição será realizada.

**Exemplo de Requisição**

``` bash
curl -X 'GET' \
  'http://127.0.0.1:4570/predicao?new=%5B%7B%22x%22%3A%2010%2C%20%22grupo%22%3A%20%22A%22%7D%2C%20%7B%22x%22%3A%209%2C%20%22grupo%22%3A%20%22B%22%7D%5D' \
  -H 'accept: application/json'
```
