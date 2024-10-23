
<!-- README.md is generated from README.Rmd. Please edit that file -->

# API para Ajustar Modelo de Regressão

<!-- badges: start -->
<!-- badges: end -->

O objetivo do projeto é a criação de uma API que interage com um conjunto de dados simulado, realiza uma regressão linear, além de predições do modelo.

## Instruções

### /inserir

Escreva a nova observação com os valores dos parâmetros nas caixas de
texto de acordo com os respectivos parâmetros (X: numérico, grupo: A, B
ou C, Y: numérico). É registrado a data e horário observados na
inserção, além de ser atribuido um valor de id para a nova observação.

Exemplo: curl -X 'POST' \
  'http://127.0.0.1:4570/inserir?x=2.4&grupo=B&y=7' \
  -H 'accept: */*' \
  -d ''


### /atualizar

Escreva o ID do registro a ser atualizado e os novos valores de x, grupo
e y. Os novos valores são inseridos no lugar da observação com o id
inserido.

Exemplo: curl -X 'PUT' \
  'http://127.0.0.1:4570/atualizar?id=3&x=5&grupo=C&y=9' \
  -H 'accept: */*'

### /deletar

Escreva o ID do registro a ser deletado.

Exemplo: curl -X 'DELETE' \
  'http://127.0.0.1:4570/deletar?id=2' \
  -H 'accept: */*'

### /gráfico

Ao executar, retorna um gráfico de dispersão dos valores observados com retas de regressão em cada grupo no conjunto de dados atual.

Exemplo: curl -X 'GET' \
  'http://127.0.0.1:4570/grafico' \
  -H 'accept: image/png'
  
### /ajustar_regressão

Ao executar, ajusta o modelo de regressão (possuindo variável resposta y) e retorna as estimativas dos coeficientes da regressão em formato JSON. Utiliza as observações contidas no atual conjunto de
dados.

Exemplo: curl -X 'GET' \
  'http://127.0.0.1:4570/ajustar_regressao' \
  -H 'accept: application/json'
  
### /residuos

Ao executar, retorna os resíduos do modelo ajustado na rota "ajustar_regressão" em
formato JSON.

Exemplo: curl -X 'GET' \
  'http://127.0.0.1:4570/residuos' \
  -H 'accept: application/json'

### /graficoresiduos

Ao executar, retorna gráficos para diagnóstico dos resíduos.

Exemplo: curl -X 'GET' \
  'http://127.0.0.1:4570/grafico_residuos' \
  -H 'accept: image/png'

### /significancia

Ao executar, retorna a significância de cada coeficiente do modelo de regressão ajustado.

Exemplo: curl -X 'GET' \
  'http://127.0.0.1:4570/significancia' \
  -H 'accept: application/json'

### /predicao

Escreva os pares de x e grupo como uma lista de listas em formato JSON.
Os múltiplos valores preditos de y retornam em formato JSON.

Exemplo: Coloque como argumento [{"x": 10, "grupo": "A"}, {"x": 9, "grupo": "B"}].

curl -X 'POST' \
  'http://127.0.0.1:4570/predicao?x=%5B%7B%22x%22%3A%2010%2C%20%22grupo%22%3A%20%22A%22%7D%2C%20%7B%22x%22%3A%209%2C%20%22grupo%22%3A%20%22B%22%7D%5D' \
  -H 'accept: application/json' \
  -d ''
