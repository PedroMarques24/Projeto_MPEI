clear

data = readtable('Dataset.csv');

% Remover linhas com dados faltantes e manter colunas relevantes
data = data(~any(ismissing(data), 2), {'Name','UserID', 'ProductID', 'Category', 'Rating', 'Price', 'Availability'});

% ---- NAIVE BAYES ----

% Seleciona um utilizador aleatóriamente
utilizador = input('Insira o UserID de utilizador (de 100 a 149): ');

% Verificar se o valor está dentro do intervalo válido
while utilizador < 100 || utilizador > 149 || mod(utilizador,1) ~= 0
    disp('Erro: O UserID deve ser um número inteiro entre 100 e 149.');
    utilizador = input('Insira o UserID de utilizador (de 100 a 149): ');
end

% Transformar categorias em índices
[data.Category_encoded, Category] = grp2idx(data.Category);

% Filtrar os produtos comprados pelo utilizador selecionado
user_data = data(data.UserID == utilizador, :);

% Usar as compras do utilizador para treinar o Naive Bayes
ratings = user_data.Rating;
y = user_data.Category_encoded;

% Garantir que category tenha categorias válidas
categories = unique(y);
prob_class = histcounts(y, [categories; max(categories) + 1]);
prob_class = prob_class / sum(prob_class);

prob_feature_given_class = cell(numel(categories), 1); 
for c = 1:numel(categories)
    idx = (y == categories(c)); 
    ratings_class = ratings(idx); 
    prob_feature_given_class{c} = (histcounts(ratings_class, 1:6) + 1) / (numel(ratings_class) + 5);
end

% ---- PREVISÃO ----

rating_previsao = 4.5; 
prob_log = log(prob_class);

% Atualiza o log das probabilidades para cada classe
for c = 1:numel(prob_feature_given_class)
    % Verifica se o rating está dentro do intervalo válido
    if rating_previsao > 0 && rating_previsao <= numel(prob_feature_given_class{c})
        % Atualiza usando a probabilidade condicional correspondente
        prob_log(c) = prob_log(c) + log(prob_feature_given_class{c}(round(rating_previsao)));
    else
        % Penaliza fortemente categorias para ratings fora do intervalo
        prob_log(c) = prob_log(c) + log(1e-10);
    end
end

% Obter a categoria prevista
[~, predicted_Category] = max(prob_log);

% Verificar tipo de "categories" e acessar corretamente
if iscell(categories)
    nomes_previstos = categories{predicted_Category};
else
    nomes_previstos = categories(predicted_Category);
end

% Chamar a função para gerar os gráficos, passando os parâmetros necessários
criar_graficos(user_data, Category, prob_log, categories, predicted_Category,utilizador);

fprintf('\nPredicted Category: %s\n', Category{nomes_previstos});