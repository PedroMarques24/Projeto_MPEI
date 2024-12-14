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