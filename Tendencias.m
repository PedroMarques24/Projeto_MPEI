data = readtable('Dataset.csv');

% Remover linhas com dados faltantes e manter colunas relevantes
data = data(~any(ismissing(data), 2), {'Name','UserID', 'ProductID', 'Category', 'Rating', 'Price', 'Availability'});

[data.Category_encoded, Category] = grp2idx(data.Category);

rating_tendencia=4.5;
% ---- Naive Bayes: tendências ----

ratings=data.Rating;
categorias = data.Category_encoded;
prob_class_geral = histcounts(categorias, [unique(categorias); max(categorias) + 1]);
prob_class_geral = prob_class_geral / sum(prob_class_geral);

prob_feature_given_class_geral = cell(numel(unique( categorias)), 1);
for c = 1:numel(unique( categorias))
    idx_geral = ( categorias == c);
    ratings_categoria =  ratings(idx_geral); 
    prob_feature_given_class_geral{c} = (histcounts(ratings_categoria, 1:6) + 1) / (numel(ratings_categoria) + 5);
end

% Atualizar o log das probabilidades gerais
prob_log_geral = log(prob_class_geral);
for c = 1:numel(prob_feature_given_class_geral)
    prob_log_geral(c) = prob_log_geral(c) + log(prob_feature_given_class_geral{c}(round(rating_tendencia)));
end

% Determinar categoria geral com maior probabilidade
[~, categoria_geral_prevista] = max(prob_log_geral);
categoria_tendencia = Category{categoria_geral_prevista};
fprintf('\nA categoria geral com maior tendência entre todos os usuários é: %s\n', categoria_tendencia);