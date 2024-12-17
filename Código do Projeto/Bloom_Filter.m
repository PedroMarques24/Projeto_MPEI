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
