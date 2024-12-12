clear

data = readtable('Dataset.csv');

% Remover linhas com dados faltantes e manter colunas relevantes
data = data(~any(ismissing(data), 2), {'Name','UserID', 'ProductID', 'Category', 'Rating'});

% ---- NAIVE BAYES ----

% Seleciona um usuário aleatoriamente
alguem = unique(data.UserID);
alguem_em_especifico = alguem(randi(numel(alguem)));

% Transformar categorias em índices
[data.Category_encoded, Category] = grp2idx(data.Category);

% Filtrar os produtos comprados pelo usuário selecionado
user_data = data(data.UserID == alguem_em_especifico, :);

% Usar as compras do usuário para treinar o Naive Bayes
X = user_data.Rating;
y = user_data.Category_encoded;

% Garantir que y tenha categorias válidas
categories = unique(y);
P_class = histcounts(y, [categories; max(categories) + 1]);
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
    if I_wanna_cry > 0 && I_wanna_cry <= numel(P_feature_given_class{c})
        Ns_o_q_e_isto(c) = Ns_o_q_e_isto(c) + log(P_feature_given_class{c}(round(I_wanna_cry)));
    else
        Ns_o_q_e_isto(c) = Ns_o_q_e_isto(c) + log(1e-10);
    end
end

% Obter a categoria prevista
[~, predicted_Category] = max(Ns_o_q_e_isto);

% Verificar tipo de "categories" e acessar corretamente
if iscell(categories)
    nomes_previstos = categories{predicted_Category};
else
    nomes_previstos = categories(predicted_Category);
end

disp('Predicted Category: ');
disp(Category(nomes_previstos));

% ---- Bloom Filter: Eliminar Produtos Já Comprados ----

% Inicializar o Bloom Filter para a categoria prevista
muito_bit = 1000; 
filtro = zeros(1, muito_bit); 

% Função de hash melhorada (simples e distribuída)
hash_function = @(x) mod(sum(double(x)), muito_bit) + 1;

% Filtrar os produtos da categoria prevista
Category_data = data(data.Category_encoded == nomes_previstos, :);

% Adicionar os produtos já comprados do usuário ao Bloom Filter
compras = user_data.ProductID;
for i = 1:numel(compras)
    idx_item = find(Category_data.ProductID == compras(i)); % Obtém o índice do item comprado na categoria
    if ~isempty(idx_item)
        filtro(hash_function(num2str(compras(i)))) = true; % Marca o item como "comprado" no Bloom Filter
    end
end

% Filtrar produtos na categoria preferida (não comprados ainda)
recomendados = Category_data;
recomendacoes_possiveis = [];

% Filtrar produtos que o usuário já comprou usando o Bloom Filter
for i = 1:height(recomendados)
    if ~filtro(hash_function(num2str(recomendados.ProductID(i)))) % Se o item não foi comprado
        recomendacoes_possiveis = [recomendacoes_possiveis; recomendados(i, :)]; % Adiciona à lista de recomendações
    end
end

% Ordenar os produtos recomendados pela coluna 'Rating' em ordem decrescente
recomendacoes_possiveis = sortrows(recomendacoes_possiveis, 'Rating', 'descend');

for c = height(recomendacoes_possiveis):-1:2
    Item1=recomendacoes_possiveis{c,3};
    Item2=recomendacoes_possiveis{c-1,3};
    if Item1==Item2
        recomendacoes_possiveis(c,:)=[];
    end
end

% Selecionar os 10 produtos mais bem classificados
if height(recomendacoes_possiveis)>10
    top_10_produtos =recomendacoes_possiveis(1:10,:);
else
    top_10_produtos =recomendacoes_possiveis(:,:);
end
% Exibir os top 10 produtos recomendados (da categoria predita)
disp('Top 10 Produtos recomendados (da categoria predita e não comprados):');
disp(top_10_produtos);

% ---- MINHASH ----
% Criar conjuntos de itens por usuário
alguem = unique(data.UserID);
num_users = numel(alguem);

set = cell(num_users, 1);
for i = 1:num_users
    set{i} = data.ProductID(data.UserID == alguem(i));
end

% Parâmetros MinHash
num_hashes = 100;  
itens = unique(data.ProductID);  
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

itens_recomendados = [set{users_parecidos(1)}];


% Excluir os produtos já comprados pelo usuário selecionado
user_purchased_itens = set{alguem_em_especifico};
itens_recomendados = setdiff(itens_recomendados, user_purchased_itens);
categoria_preferida = nomes_previstos;
itens_na_categoria = data.ProductID(data.Category_encoded == categoria_preferida);
itens_recomendados = intersect(itens_recomendados, itens_na_categoria);

% Exibir os produtos recomendados
disp('Produtos recomendados para o usuário com base no usuário mais semelhante e na categoria preferida:');
disp(unique(data.Name(itens_recomendados)));

% ---- RESULTADOS ----
% Exibir similaridade entre o usuário escolhido e os outros
disp(['Usuário selecionado: ', num2str(alguem(alguem_em_especifico))]);
for ola = 1:numel(users_parecidos)
    disp(['Similaridade com usuário ', num2str(alguem(users_parecidos(ola))), ': ', num2str(similarities(users_parecidos(ola)))]);

end
