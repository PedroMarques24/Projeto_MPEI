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
