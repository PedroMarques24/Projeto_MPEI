function prob_log = atualizar_prob_log(prob_log, rating_previsao, prob_feature_given_class)
    % Função para atualizar o log das probabilidades a posteriori 
    % com base no rating fornecido e nas probabilidades condicionais.

    % prob_log: vetor inicial de log das probabilidades (a priori ou acumuladas)
    % rating_previsao: o rating usado para ajustar as probabilidades
    % prob_feature_given_class: cell array contendo as distribuições condicionais dos ratings para cada classe

    % Atualiza o log das probabilidades para cada classe
    for c = 1:numel(prob_feature_given_class)
        % Verifica se o rating está dentro do intervalo válido
        if rating_previsao > 0 && rating_previsao <= numel(prob_feature_given_class{c})
            % Atualiza usando a probabilidade condicional correspondente
            prob_log(c) = prob_log(c) + log(prob_feature_given_class{c}(round(rating_previsao)));
        else
            % Penaliza fortemente categorias para ratings fora do intervalo
            prob_log(c) = prob_log(c) + log(1e-10);
        end
    end
end
