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
