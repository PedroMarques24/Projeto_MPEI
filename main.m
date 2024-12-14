clear

data = readtable('Dataset.csv');

% Remover linhas com dados faltantes e manter colunas relevantes
data = data(~any(ismissing(data), 2), {'Name','UserID', 'ProductID', 'Category', 'Rating', 'Price', 'Availability'});

%% ---- NAIVE BAYES ----

% Seleciona um utilizador aleatóriamente
utilizador = input('Insira o UserID de utilizador (de 100 a 149): ');

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

prob_log = atualizar_prob_log(prob_log, rating_previsao, prob_feature_given_class);

% Obter a categoria prevista
[~, predicted_Category] = max(prob_log);

% Verificar tipo de "categories" e acessar corretamente
if iscell(categories)
    nomes_previstos = categories{predicted_Category};
else
    nomes_previstos = categories(predicted_Category);
end

fprintf('Predicted Category: %s\n', Category{nomes_previstos});

%% ---- Bloom Filter: Eliminar Produtos Já Comprados ----

% Inicializar o Bloom Filter para a categoria prevista
filtro_tamanho = 1000; 
filtro = zeros(1, filtro_tamanho); 

% Adicionar os produtos já comprados pelo utilizador ao Bloom Filter
compras = user_data.ProductID;
for i = 1:numel(compras)
    hash_idx = hash_function(compras(i), filtro_tamanho); % Calcular o índice hash
    filtro(hash_idx) = true; % Marcar o produto como "comprado"
end

% Filtrar os produtos da categoria prevista
Category_data = data(data.Category_encoded == nomes_previstos, :);

% Filtrar produtos que o utilizador já comprou usando o Bloom Filter
recomendacoes_possiveis = [];
for j = 1:height(Category_data)
    hash_idx = hash_function(Category_data.ProductID(j), filtro_tamanho); % Calcular o índice hash
    if ~filtro(hash_idx) % Se o produto não foi comprado
        recomendacoes_possiveis = [recomendacoes_possiveis; Category_data(j, :)]; % Adiciona à lista de recomendações
    end
end

% Ordenar os produtos recomendados pela coluna 'Rating' em ordem decrescente
recomendacoes_possiveis = sortrows(recomendacoes_possiveis, 'Rating', 'descend');

% Remover produtos duplicados
for c = height(recomendacoes_possiveis):-1:2
    Item1 = recomendacoes_possiveis{c, 'ProductID'};
    Item2 = recomendacoes_possiveis{c-1, 'ProductID'};
    if Item1 == Item2
        recomendacoes_possiveis(c, :) = [];
    end
end

produtos = recomendacoes_possiveis(1:end, :);

% Exibir os produtos recomendados (da categoria predita e não comprados)
fprintf('\n                      Produtos da categoria %s com as melhores avaliações.                   \n',Category{nomes_previstos});
fprintf('=====================================================================================================================\n');
fprintf('| %-3s | %-50s | %-10s | %-9s | %-9s | %-12s |\n', ...
    'Nº', 'Nome do Produto', 'ID Produto', 'Avaliação', 'Preço', 'Disponibilidade');
fprintf('---------------------------------------------------------------------------------------------------------------------\n');

for p = 1:height(produtos)
    fprintf('| %-3d | %-50s | %-10d | %-9.1f | %-9.2f | %-12s \n', ...
        p, ...
        produtos.Name{p}, ...
        produtos.ProductID(p), ...
        produtos.Rating(p), ...
        produtos.Price(p), ...
        produtos.Availability{p});
end

fprintf('---------------------------------------------------------------------------------------------------------------------\n');

%% ---- MINHASH ----
% Criar conjuntos de itens por utilizador
alguem = unique(data.UserID);
num_users = numel(alguem);

Set = cell(num_users, 1);
for i = 1:num_users
    Set{i} = data.ProductID(data.UserID == alguem(i));
end

% Parâmetros MinHash
num_hashes = 100;  
itens = unique(data.ProductID);  
num_itens = numel(itens);

% Criar assinaturas MinHash
assinaturas = calcular_assinaturas(Set, num_users, num_hashes, num_itens);

% Selecionar o utilizador escolhido aleatoriamente
utilizador_em_especifico = utilizador - 100 + 1; %50 utilizadares de 100 a 149

% Calcular similaridade com os outros utilizador
similarities = zeros(num_users, 1);
for ns = 1:num_users
    if ns ~= utilizador_em_especifico
        similarities(ns) = compute_similarity(utilizador_em_especifico, ns, assinaturas, num_hashes);
    else
        similarities(ns) = -1;
    end
end

% Encontrar os utilizadores mais similares (top 5)
[~, idx_users_parecidos] = sort(similarities, 'descend');
users_parecidos = idx_users_parecidos(1:5);

% Obter os produtos comprados pelos utilizador mais similares
itens_recomendados = [];
for u = 1:numel(users_parecidos)
    itens_recomendados = [itens_recomendados; Set{users_parecidos(u)}];
end

% Excluir os produtos já comprados pelo utilizador selecionado
user_purchased_itens = Set{utilizador_em_especifico};
itens_recomendados = setdiff(itens_recomendados, user_purchased_itens);

% Filtrar itens pela categoria predita
categoria_preferida = nomes_previstos; % Categoria predita
itens_na_categoria = data.ProductID(data.Category_encoded == categoria_preferida);
itens_recomendados = intersect(itens_recomendados, itens_na_categoria);

% Exibir os produtos recomendados
if isempty(itens_recomendados)
    disp('Nenhum produto disponível para recomendação na categoria predita.');
else
    recomendados = unique(data.Name(ismember(data.ProductID, itens_recomendados)));
    % Exibir os produtos recomendados (da categoria predita e não comprados)
    fprintf('\n            Produtos recomendados com base no utilizador mais semelhante da categoria %s.               \n',Category{nomes_previstos});
    fprintf('=====================================================================================================================\n');
    fprintf('| %-3s | %-50s | %-10s | %-9s | %-9s | %-12s |\n', ...
        'Nº', 'Nome do Produto', 'ID Produto', 'Avaliação', 'Preço', 'Disponibilidade');
    fprintf('---------------------------------------------------------------------------------------------------------------------\n');
    
    for p = 1:numel(recomendados)
        % Buscar os detalhes dos produtos recomendados a partir dos seus nomes
        produto_info = data(strcmp(data.Name, recomendados{p}), :);
        if ~isempty(produto_info)
            fprintf('| %-3d | %-50s | %-10d | %-9.1f | %-9.2f | %-12s \n', ...
                p, ...
                produto_info.Name{1}, ...
                produto_info.ProductID(1), ...
                produto_info.Rating(1), ...
                produto_info.Price(1), ...
                produto_info.Availability{1});
        end
    end
    
    fprintf('---------------------------------------------------------------------------------------------------------------------\n');
end

% ---- RESULTADOS ----
% Exibir similaridade entre o utilizador escolhido e os outros
fprintf('\n===== Utilizadores Semelhantes =====\n');
disp(['Usuário selecionado: ', num2str(alguem(utilizador_em_especifico))]);
for x = 1:numel(users_parecidos)
    disp(['Similaridade com usuário ', num2str(alguem(users_parecidos(x))), ': ', num2str(similarities(users_parecidos(x)))]);
end
