function hash_index = hash_function(item, filtro_tamanho)
    % hash_function: Calcula o índice hash para um item dado o tamanho do Bloom Filter.
    %
    % Parâmetros:
    % item (qualquer) -> O identificador do item (geralmente um ProductID) a ser processado.
    % filtro_tamanho -> O tamanho do Bloom Filter (número de bits no vetor binário).
    %
    % Retorno:
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
