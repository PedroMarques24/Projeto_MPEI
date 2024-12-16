data = readtable('Dataset.csv');

% Remover linhas com dados faltantes e manter colunas relevantes
data = data(~any(ismissing(data), 2), {'Name','UserID', 'ProductID', 'Category', 'Rating', 'Price', 'Availability'});

[data.Category_encoded, Category] = grp2idx(data.Category);

rating_tendencia = 4.5;
% ---- Naive Bayes: tendências ----

ratings = data.Rating;
categorias = data.Category_encoded;
num_classes = numel(unique(categorias));
prob_class_geral = histcounts(categorias, [unique(categorias); max(categorias) + 1]);
prob_class_geral = prob_class_geral / sum(prob_class_geral);

prob_feature_given_class_geral = cell(numel(unique( categorias)), 1);
for c = 1:numel(unique( categorias))
    idx_geral = ( categorias == c);
    ratings_categoria =  ratings(idx_geral); 
    prob_feature_given_class_geral{c} = (histcounts(ratings_categoria, 1:6) + 1) / (numel(ratings_categoria) + 5);
end

prob_log_geral = log(prob_class_geral);

% Atualizar o log das probabilidades gerais
prob_log_geral = atualizar_prob_log(prob_log_geral, rating_tendencia, prob_feature_given_class_geral);

% Rankear categorias com maior tendência
[~, ordem_tendencia] = sort(prob_log_geral, 'descend');
categorias_tendencia = Category(ordem_tendencia);

% Exibir as categorias com maior tendência
fprintf('\nCategorias com maior tendência:\n');
for i = 1:min(5, num_classes) % Exibir top 5 categorias
    fprintf('%d. %s (Score: %.3f)\n', i, categorias_tendencia{i}, prob_log_geral(ordem_tendencia(i)));
end
