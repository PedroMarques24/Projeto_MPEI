dataset = 'Reviews.csv';
data_demasiado_grande = readtable(dataset, 'Delimiter', ',', 'TextType', 'string');
disp(data_demasiado_grande(1:5,:));

data = data_demasiado_grande(:, ["ProductId", "UserId", "Score"]);
disp(data(1:5,:));

avaliacoes = data_demasiado_grande.("Summary");
disp(avaliacoes(1));

Retirar_virgulas_e_assim = regexprep(avaliacoes, '[^\w\s]', '');
minusculo = lower(Retirar_virgulas_e_assim);
palavras_irrelevantes = ["a", "an", "the", "and", "but", "or", "in", "on", "with", "at", "for", "by","it","this"];

palavras = split(join(minusculo));
palavras = palavras(~ismember(palavras, palavras_irrelevantes));
palavras_unicas = unique(palavras);
writetable(data, 'dataset_util.csv');

numero_de_palavras = countcats(categorical(palavras));
[numeros_organizados, indices_organizados] = sort(numero_de_palavras, 'descend');
palavras_organizadas = palavras_unicas(indices_organizados);

disp(table(palavras_organizadas(1:10), numeros_organizados(1:10), 'VariableNames', {'Palavra', 'Contagem'}));

palavras_importantes = palavras_unicas(indices_organizados(1:1000)); 

% Redefinir matriz com palavras importantes
num_avaliacoes = length(palavras);
num_palavras = length(palavras_importantes);
TREINO = zeros(num_avaliacoes, num_palavras);

% Atualizar preenchimento da matriz
for i = 1:num_avaliacoes
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
classes = scores >= 4; % 1 para positivo, 0 para negativo
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
total_palavras_NEG = sum(contagem_palavras_NEG) + length(palavras_unicas);
prob_palavra_dado_NEG = contagem_palavras_NEG / total_palavras_NEG;

% Avaliação de teste
avaliacao_teste = "predictable with no fun";
palavras_teste = split(avaliacao_teste);

% Calcular probabilidade de NEG
prob_NEG = pNEG;
for p = 1:length(palavras_teste)
    if ismember(palavras_teste{p}, palavras_unicas)
        idx = find(palavras_unicas == palavras_teste{p});
        prob_NEG = prob_NEG * prob_palavra_dado_NEG(idx);
    end
end

% Calcular probabilidade de POS
prob_POS = pPOS;
for p = 1:length(palavras_teste)
    if ismember(palavras_teste{p}, palavras_unicas)
        idx = find(palavras_unicas == palavras_teste{p});
        prob_POS = prob_POS * prob_palavra_dado_POS(idx);
    end
end

% Decisão final
if prob_POS > prob_NEG
    disp('Classificação: POSITIVA');
else
    disp('Classificação: NEGATIVA');
end
