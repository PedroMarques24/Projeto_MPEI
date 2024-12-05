clear;
dataset = 'Reviews.csv';
data_demasiado_grande = readtable(dataset, 'Delimiter', ',', 'TextType', 'string');
disp(data_demasiado_grande(1:5,:));

data = data_demasiado_grande(:, ["ProductId", "UserId", "Score"]);
disp(data(1:5,:));

scores=data.("Score");
avaliacoes = data_demasiado_grande.("Summary");
%disp(avaliacoes(1));

Retirar_virgulas_e_assim = regexprep(avaliacoes, '[^\w\s]', '');
minusculo = lower(Retirar_virgulas_e_assim);
palavras_irrelevantes = { ...
    'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', ...
    'an', 'and', 'any', 'are', 'aren''t', 'as', 'at', 'be', 'because', ...
    'been', 'before', 'being', 'below', 'between', 'both', 'but', 'by', ...
    'can''t', 'cannot', 'could', 'couldn''t', 'did', 'didn''t', 'do', ...
    'does', 'doesn''t', 'doing', 'don''t', 'down', 'during', 'each', ...
    'few', 'for', 'from', 'further', 'had', 'hadn''t', 'has', 'hasn''t', ...
    'have', 'haven''t', 'having', 'he', 'he''d', 'he''ll', 'he''s', ...
    'her', 'here', 'here''s', 'hers', 'herself', 'him', 'himself', ...
    'his', 'how', 'how''s', 'i', 'i''d', 'i''ll', 'i''m', 'i''ve', ...
    'if', 'in', 'into', 'is', 'isn''t', 'it', 'it''s', 'its', 'itself', ...
    'let''s', 'me', 'more', 'most', 'mustn''t', 'my', 'myself', 'no', ...
    'nor', 'not', 'of', 'off', 'on', 'once', 'only', 'or', 'other', ...
    'ought', 'our', 'ours', 'ourselves', 'out', 'over', 'own', 'same', ...
    'shan''t', 'she', 'she''d', 'she''ll', 'she''s', 'should', 'shouldn''t', ...
    'so', 'some', 'such', 'than', 'that', 'that''s', 'the', 'their', ...
    'theirs', 'them', 'themselves', 'then', 'there', 'there''s', ...
    'these', 'they', 'they''d', 'they''ll', 'they''re', 'they''ve', ...
    'this', 'those', 'through', 'to', 'too', 'under', 'until', 'up', ...
    'very', 'was', 'wasn''t', 'we', 'we''d', 'we''ll', 'we''re', ...
    'we''ve', 'were', 'weren''t', 'what', 'what''s', 'when', 'when''s', ...
    'where', 'where''s', 'which', 'while', 'who', 'who''s', 'whom', ...
    'why', 'why''s', 'with', 'won''t', 'would', 'wouldn''t', 'you', ...
    'you''d', 'you''ll', 'you''re', 'you''ve', 'your', 'yours', ...
    'yourself', 'yourselves' ...
};


palavras = split(join(minusculo));
palavras = palavras(~ismember(palavras, palavras_irrelevantes));
palavras_unicas = unique(palavras);
writetable(data, 'dataset_util.csv');

numero_de_palavras = countcats(categorical(palavras));
[numeros_organizados, indices_organizados] = sort(numero_de_palavras, 'descend');
palavras_organizadas = palavras_unicas(indices_organizados);

%disp(table(palavras_organizadas(1:10), numeros_organizados(1:10), 'VariableNames', {'Palavra', 'Contagem'}));

palavras_importantes = palavras_unicas(indices_organizados(1:500)); 
disp(table(palavras_importantes, numeros_organizados(1:500), 'VariableNames', {'Palavra', 'Contagem'}));

% Redefinir matriz com palavras importantes
num_avaliacoes = length(avaliacoes);
num_palavras = length(palavras_importantes);
TREINO = zeros(num_avaliacoes, num_palavras);

% Atualizar preenchimento da matriz
for i = 1:num_avaliacoes
    avaliacao = avaliacoes{i};
    palavras=split(avaliacao);
    for j = 1:num_palavras
        palavra_importante = palavras_importantes(j);
        ocorrencias = sum(palavras == palavra_importante);
        %guardar contagem em (frase, palavra_unica)
        TREINO(i, j) = ocorrencias;
    end
end

% Visualizar matriz de treino
imagesc(TREINO);

% Definir classes baseadas no score (exemplo: Score >= 4 é positivo, <4 é negativo)
classes = scores >= 3; % 1 para positivo, 0 para negativo
classes = categorical(classes, [0 1], {'NEG', 'POS'});

% Probabilidades a priori
pNEG = sum(classes == 'NEG') / length(classes);
pPOS = sum(classes == 'POS') / length(classes);

% Selecionar linhas de treino por classe
TREINO_POS = TREINO(classes == 'POS', :);
TREINO_NEG = TREINO(classes == 'NEG', :);

% Cálculo para palavras em POS
contagem_palavras_POS = sum(TREINO_POS) + 1; % Suavização de Laplace
total_palavras_POS = sum(contagem_palavras_POS) + length(palavras_unicas);
prob_palavra_dado_POS = contagem_palavras_POS / total_palavras_POS;

% Cálculo para palavras em NEG
contagem_palavras_NEG = sum(TREINO_NEG) + 1; % Suavização de Laplace
total_palavras_NEG = sum(contagem_palavras_NEG) + num_palavras;
prob_palavra_dado_NEG = contagem_palavras_NEG / total_palavras_NEG;

% Avaliação de teste
avaliacao_teste = "bad";
palavras_teste = split(avaliacao_teste);

% Calcular probabilidade de NEG
prob_NEG = pNEG;
for p = 1:length(palavras_teste)
    if any(strcmp(palavras_unicas, palavras_teste{p}))
        idx = find(strcmp(palavras_unicas, palavras_teste{p})); % Localizar índice correto
        if idx <= length(prob_palavra_dado_NEG) % Garantir que o índice não excede o tamanho
            prob_NEG = prob_NEG * prob_palavra_dado_NEG(idx);
        end
    end
end

% Calcular probabilidade de POS
prob_POS = pPOS;
for p = 1:length(palavras_teste)
    if any(strcmp(palavras_unicas, palavras_teste{p}))
        idx = find(strcmp(palavras_unicas, palavras_teste{p})); % Localizar índice correto
        if idx <= length(prob_palavra_dado_POS) % Garantir que o índice não excede o tamanho
            prob_POS = prob_POS * prob_palavra_dado_POS(idx);
        end
    end
end

% Decisão final
if prob_POS > prob_NEG
    disp('Classificação: POSITIVA');
else
    disp('Classificação: NEGATIVA');
end
