clear

data = readtable('Dataset.csv');

% Remover linhas com dados faltantes e manter colunas relevantes
data = data(~any(ismissing(data), 2), {'Name','UserID', 'ProductID', 'Category', 'Rating', 'Price', 'Availability'});

% ---- NAIVE BAYES ----

% Seleciona um utilizador aleatóriamente
alguem = unique(data.UserID);
utilizador = alguem(randi(numel(alguem)));

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

% Atualizar as probabilidades logarítmicas usando a função auxiliar
prob_log = atualizar_prob_log(prob_log, rating_previsao, prob_feature_given_class);

function prob_log = atualizar_prob_log(prob_log, rating_previsao, prob_feature_given_class)
    % Função para atualizar o log das probabilidades a posteriori 
    % com base no rating fornecido e nas probabilidades condicionais.

    % prob_log: vetor inicial de log das probabilidades (a priori ou acumuladas)
    % rating_previsao: o rating usado para ajustar as probabilidades
    % prob_feature_given_class: cell array contendo as distribuições condicionais dos ratings para cada classe

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
end

% Obter a categoria prevista
[~, predicted_Category] = max(prob_log);

% Verificar tipo de "categories" e acessar corretamente
if iscell(categories)
    nomes_previstos = categories{predicted_Category};
else
    nomes_previstos = categories(predicted_Category);
end

fprintf('\nPredicted Category: %s\n', Category{nomes_previstos});

%% ---- Bloom Filter: Eliminar Produtos Já Comprados ----

% Inicializar o Bloom Filter para a categoria prevista
filtro_tamanho = 1540; 
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

function hash_index = hash_function(item, filtro_tamanho)
    % hash_function: Calcula o índice hash para um item dado o tamanho do Bloom Filter.

    % item (qualquer) -> O identificador do item (geralmente um ProductID) a ser processado.
    % filtro_tamanho -> O tamanho do Bloom Filter (número de bits no vetor binário).
    % hash_index -> O índice calculado dentro do intervalo [1, filtro_tamanho].

    % Converter o item para string se necessário
    if ~ischar(item) && ~isstring(item)
        item = num2str(item); % Converte o item para string
    end

    % Converter a string para valores ASCII e somá-los
    ascii_sum = sum(double(item));

    % Calcular o índice hash usando módulo e ajustar para índices MATLAB
    hash_index = mod(ascii_sum, filtro_tamanho) + 1;
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

% Selecionar os 10 produtos mais bem classificados
% Se não tiverem 10 produtos imprime a lista toda de produtos que o
% utilizador ainda não comprou da categoria em questão
if height(recomendacoes_possiveis)>10
    produtos =recomendacoes_possiveis(1:10,:);
else
    produtos =recomendacoes_possiveis(:,:);
end

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

function assinaturas = calcular_assinaturas(set, num_users, num_hashes, num_itens)
    
    % Inicializa a matriz de assinaturas (k funções de hash por Nt usuários)
    assinaturas = inf(num_hashes, num_users);

    % Itera pelas k funções de hash
    for hf = 1:num_hashes

        % Itera pelos utilizadores (conjuntos de itens)
        for c = 1:num_users
            % Obtém os itens comprados pelo utilizador c
            conjunto = set{c};
            hc = zeros(1, length(conjunto)); % Vetor para armazenar os valores de hash

            % Itera pelos elementos do conjunto de itens
            for nelem = 1:length(conjunto)
                elemento = conjunto(nelem); % Produto/Item
                hc(nelem) = hash_function_shingles(elemento, hf, num_itens); % Aplica a função de hash
            end

            % Calcula o valor mínimo entre os valores de hash
            minhash = min(hc);
            
            % Armazena o valor mínimo na matriz de assinaturas
            assinaturas(hf, c) = minhash;
        end
    end
end

function hash_val = hash_function_shingles(shingle, hf, num_itens)
    % Número primo para melhorar a dispersão dos valores
    primo1 = 31;
    primo2 = 97;
    
    % Multiplicação modular para maior dispersão
    hash_val = mod(primo1 * shingle + primo2 * hf, num_itens) + 1;
end

% O número de hash functions(num_hashes) é 100.
% Os números 31 e 97 foram escolhidos porque são suficientemente pequenos 
% para garantir eficiência computacional, mas grandes o suficiente para 
% evitar colisões em muitas entradas diferentes.

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

function similarity = compute_similarity(user1, user2, minhash_signatures, num_hashes)

% Função para calcular a similaridade entre dois utilizadores com base em assinaturas MinHash
% user1 -> Índice do primeiro utilizador (utilizador principal)
% user2 -> Índice do segundo utilizador (utilizador a comparar)
% minhash_signatures -> Matriz onde cada coluna representa as assinaturas MinHash
% de um utilizador, e cada linha corresponde ao valor de uma hash específica.
% num_hashes -> Número total de funções de hash usadas para gerar as assinaturas.
% similarity -> Similaridade de Jaccard aproximada entre os dois utilizadores,
% calculada pela fração de valores iguais entre as assinaturas MinHash.

    % Comparar as assinaturas MinHash dos dois utilizadores e contar quantas hashes são iguais
    num_matches = sum(minhash_signatures(:, user1) == minhash_signatures(:, user2));
    
    % Calcular a similaridade como a proporção de hashes iguais em relação ao total de hashes
    similarity = num_matches / num_hashes;
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

data = readtable('Dataset.csv');


%% ---- Naive Bayes: tendências ----

[data.Category_encoded, Category] = grp2idx(data.Category);

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
prob_log_geral = atualizar_prob_log(prob_log_geral, rating_previsao, prob_feature_given_class_geral);

% Rankear categorias com maior tendência
[~, ordem_tendencia] = sort(prob_log_geral, 'descend');
categorias_tendencia = Category(ordem_tendencia);

% Exibir as categorias com maior tendência
fprintf('\nCategorias com maior tendência:\n');
for i = 1:min(5, num_classes) % Exibir top 5 categorias
    fprintf('%d. %s (Score: %.3f)\n', i, categorias_tendencia{i}, prob_log_geral(ordem_tendencia(i)));
end
