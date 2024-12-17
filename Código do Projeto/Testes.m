%% -------- Naive Bayes -> Teste --------

% Executa o script Naive_Bayes.m, onde o teste é realizado diretamente.
run('Naive_Bayes.m')  

% Chamar a função para gerar os gráficos, passando os parâmetros necessários
criar_graficos(user_data, Category, prob_log, categories, predicted_Category,utilizador);
%% ------- Bloom filter -> Teste --------

% Obtém a lista de produtos comprados pelo utilizador específico (utilizador) a partir dos dados disponíveis.
lista_de_produtos = data(data.UserID==utilizador,"Name");
disp(lista_de_produtos);

% Executa o script Bloom_Filter.m, que contém a implementação do filtro de Bloom.
run('Bloom_Filter.m');

% Testa o Bloom Filter comparando os produtos no filtro com a lista de produtos do utilizador.
teste_bloom_filter = intersect(produtos.Name, lista_de_produtos.Name);

% Verifica se o teste do filtro de Bloom foi bem-sucedido.
if isempty(teste_bloom_filter)
    fprintf("\n--------------------------\n")
    fprintf("\nPassou no teste! \n") % Teste aprovado: os produtos recomendados são diferentes dos produtos comprados.
    fprintf("\n--------------------------\n")
else
    fprintf("\n--------------------------\n")
    fprintf("\nNão passou no teste! \n") % Teste falhou: há produtos recomendados iguais dos produtos comprados.
    fprintf("\n--------------------------\n")
end

%% --------- MinHash -> Teste ----------

% Executa o script Minhash.m
run('Minhash.m');

% Inicializa um vetor para armazenar os produtos comprados pelos utilizadores semelhantes.
elementos=[];
for x = 1:numel(users_parecidos)
    % Obtém os produtos associados a cada utilizador semelhante.
    produtos = data(data.UserID == alguem(users_parecidos(x)), 'Name');
    for produto = 1:numel(produtos)
        % Adiciona cada produto encontrado à lista de elementos.
        elementos = [elementos produtos{produto,1}];
    end
end

% Compara os produtos recomendados com os produtos comprados pelos utilizadores semelhantes.
teste_do_minhash = intersect(recomendados,elementos);

% Verifica se todos os produtos recomendados estão presentes na lista de
% produtos comprados pelos utilizadores semelhantes
if numel(teste_do_minhash) == numel(recomendados)
    fprintf("\n--------------------------\n")
    fprintf("\nPassou no teste! \n") % Teste aprovado: todos os recomendados estão no conjunto.
    fprintf("\n--------------------------\n")
else 
    fprintf("\n--------------------------\n")
    fprintf("Não passou no teste! \n") % Teste falhou: nem todos os recomendados estão presentes.
    fprintf("\n--------------------------\n")
end
