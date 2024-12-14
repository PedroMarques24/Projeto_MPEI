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
