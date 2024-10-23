
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Trabalho3_ME918

<!-- badges: start -->
<!-- badges: end -->

O objetivo do projeto Trabalho3_ME918 é a criação de uma API que
interage com um conjunto de dados simulado, realiza uma regressão
linear, além de predições do modelo.

## Instruções

### /inserir

Escreva a nova observação com os valores dos parâmetros nas caixas de
texto de acordo com os respectivos parâmetros (X: numérico, grupo: A B
ou C, Y: numérico). É registrado a data e horário observados na
inserção, além de ser atribuido um valor de id para a nova observação.

### /atualizar

Escreva o ID do registro a ser atualizado e os novos valores de x, grupo
e y. Os novos valores são inseridos no lugar da observação com o id
inserido.

### /deletar

Escreva o ID do registro ou observação a ser deletada.

### /gráfico

Ao executar, retorna um gráfico de disperção das observações contidas no
atual conjunto de dados.

### /regressão

Ao executar, retorna as estimativas dos coeficientes da regressão em
formato JSON. Utiliza as observações contidas no atual conjunto de
dados.

### /residuos

Ao executar, retorna os resíduos do modelo ajustado na regressão em
formato JSON.

### /graficoresiduos

Ao executar, retorna o gráfico de se

### /significancia

### /predicao

Escreva o valor de x e o grupo da observação para a predição do valor de
y segundo a regressão executada.

### /predictions

Escreva os pares de x e grupo como uma lista de listas em formato JSON.
Os múltiplos valores preditos de y retornam em formato JSON.
