clear

data = readtable('electronics.csv');

data = data(~any(ismissing(data), 2), {'user_id', 'item_id', 'category', 'rating', 'brand'});

% ---- NAIVE BAYES ----

% Seleciona um usuário aleatoriamente
alguem = unique(data.user_id);
alguem_em_especifico = alguem(randi(numel(alguem)));

% Transformar categorias em indices
[data.category_encoded, categories] = grp2idx(data.category);

% Filtrar os produtos comprados pelo usuário selecionado
user_data = data(data.user_id == alguem_em_especifico, :);

% Usar as compras do usuário para treinar o Naive Bayes
X = [user_data.rating];
y = user_data.category_encoded;
categories = unique(y);
P_class = histcounts(y, [categories; max(categories)+1]);
P_class = P_class / sum(P_class);
P_feature_given_class = cell(numel(categories), 1); 
for c = 1:numel(categories)
    idx = (y == categories(c)); 
    X_class = X(idx); 
    P_feature_given_class{c} = (histcounts(X_class, 1:6) + 1) / (numel(X_class) + 5);
end

% ---- PREVISÃO ----

I_wanna_cry = 4.5; 
Ns_o_q_e_isto = log(P_class);

for c = 1:numel(categories)
    feature_value = I_wanna_cry(1);
    if feature_value > 0 && feature_value <= numel(P_feature_given_class{c})
        Ns_o_q_e_isto(c) = Ns_o_q_e_isto(c) + log(P_feature_given_class{c}(round(feature_value)));
    else
        Ns_o_q_e_isto(c) = Ns_o_q_e_isto(c) + log(1e-10);
    end
end

% Obter a categoria prevista
[~, predicted_category] = max(Ns_o_q_e_isto);
nomes_categorias = unique(data.category);
nomes_previstos = nomes_categorias(predicted_category);
disp('Predicted Category: ');
disp(nomes_previstos);

% ---- Bloom Filter: Eliminar Produtos Já Comprados ----

% Inicializar o Bloom Filter para a categoria prevista
muito_bit = 1000; 
filtro = false(1, muito_bit); 
hash_function = @(x) mod(sum(double(x)), muito_bit) + 1;

% Filtrar os produtos da categoria prevista
category_data = data(strcmp(data.category, nomes_previstos), :);

% Adicionar os produtos já comprados do usuário ao Bloom Filter
compras = user_data.item_id;
for i = 1:numel(compras)
    if any(strcmp(category_data.item_id, num2str(compras(i))))
        filtro(hash_function(num2str(compras(i)))) = true;
    end
end

% Filtrar produtos na categoria preferida (não comprados ainda)
recomendados = category_data;
recomendacoes_possiveis = [];

% Filtrar produtos que o usuário já comprou usando o Bloom Filter
for i = 1:height(recomendados)
    if ~filtro(hash_function(num2str(recomendados.item_id(i))))
        recomendacoes_possiveis = [recomendacoes_possiveis; recomendados(i,:)];
    end
end

% Ordenar os produtos recomendados com base na média de avaliações
media_ratings = grpstats(data, 'item_id', {'mean'}, 'DataVars', 'rating');
[~, idx_sorted] = sort(media_ratings.mean_rating, 'descend');

% Selecionar os 10 produtos mais bem classificados
top_10_produtos = media_ratings(idx_sorted(1:10), :);

% Exibir os top 10 produtos recomendados (da categoria predita)
disp('Top 10 Produtos recomendados (da categoria predita e não comprados):');
disp(top_10_produtos);

% ---- MINHASH ----
% Criar conjuntos de itens por usuário
alguem = unique(data.user_id);
num_users = numel(alguem);

set = cell(num_users, 1);
for i = 1:num_users
    set{i} = data.item_id(data.user_id == alguem(i));
end

% Parâmetros MinHash
num_hashes = 100;  
itens = unique(data.item_id);  
num_itens = numel(itens);

% Criar assinaturas MinHash
assinaturas = inf(num_hashes, num_users);

% Função de hash (simples, pode ser ajustada)
hash_functions = @(x, i) mod((7 * x + i), num_itens) + 1;

for fomeeeeee = 1:num_hashes
    for sonooooo = 1:num_users
        itens_set = set{sonooooo};
        hashed_values = arrayfun(@(x) hash_functions(x, fomeeeeee), itens_set);
        assinaturas(fomeeeeee, sonooooo) = min(hashed_values);
    end
end

% Função para calcular similaridade Jaccard usando MinHash
function similarity = compute_similarity(user1, user2, minhash_signatures, num_hashes)
    similarity = sum(minhash_signatures(:, user1) == minhash_signatures(:, user2)) / num_hashes;
end

% Selecionar o usuário escolhido aleatoriamente
alguem_em_especifico = randi(num_users);

% Calcular similaridade com os outros usuários
similarities = zeros(num_users, 1);
for ns = 1:num_users
    if ns ~= alguem_em_especifico
        similarities(ns) = compute_similarity(alguem_em_especifico, ns, assinaturas, num_hashes);
    else
        similarities(ns) = -1;
    end
end

% Encontrar os usuários mais similares (top 5)
[~, idx_users_parecidos] = sort(similarities, 'descend');
users_parecidos = idx_users_parecidos(1:5);

% Obter os produtos comprados pelos usuários mais similares
itens_recomendados = [];
for i = 1:numel(users_parecidos)
    similar_user = users_parecidos(i);
    itens_recomendados = [itens_recomendados; set{similar_user}];
end

% Excluir os produtos já comprados pelo usuário selecionado
user_purchased_itens = set{alguem_em_especifico};
itens_recomendados = setdiff(itens_recomendados, user_purchased_itens);

% Exibir os produtos recomendados
disp('ID dos produtos recomendados para o usuário com base em usuários similares (O dataset atual n tem nomes):');
disp(itens_recomendados);

% ---- RESULTADOS ----
% Exibir similaridade entre o usuário escolhido e os outros
disp(['Usuário selecionado: ', num2str(alguem_em_especifico)]);
for ola = 1:numel(users_parecidos)
    disp(['Similaridade com usuário ', num2str(users_parecidos(ola)), ': ', num2str(similarities(users_parecidos(ola)))]);
end
