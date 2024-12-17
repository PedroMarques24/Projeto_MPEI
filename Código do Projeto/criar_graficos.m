function criar_graficos(user_data, Category, prob_log, categories, predicted_Category, utilizador)
    % Função para gerar os gráficos para o utilizador
    
    % Gerar gráfico circular das categorias de produtos comprados
    if isempty(user_data)
        disp('Este utilizador não comprou produtos.');
    else
        % Criar waitbar para os dois gráficos
        h = waitbar(0, 'Iniciando criação dos gráficos...');
        pause(1);

        % Contar a quantidade de produtos por categoria
        categoria_counts = groupcounts(user_data.Category);
        
        % Atualizar waitbar
        waitbar(0.5, h, 'Preparando dados para os gráficos...');
        
        % Criar subplots
        figure;

        % Definir o tamanho da janela da figura (ajustando a propriedade 'Position')
        set(gcf, 'Position', [100, 100, 1300, 600]); % [x, y, largura, altura]

        % Gráfico circular
        subplot(1, 2, 1);
        pie(categoria_counts);
        legend(unique(user_data.Category), 'Location', 'bestoutside');
        title(['Distribuição de Produtos por Categoria para o Utilizador ', num2str(utilizador)]);
    
        % --- FINALIZAÇÃO DO GRÁFICO DE BARRAS ---
        % Criar gráfico de barras para as probabilidades logarítmicas
        subplot(1, 2, 2);
        bar(prob_log);
        title('Logaritmo das Probabilidades para cada Categoria');
        xlabel('Categorias');
        ylabel('Log(P(C|F))');
        set(gca, 'XTickLabel', Category(categories), 'XTick', 1:length(categories));
        xtickangle(45);  % Rotaciona os rótulos do eixo X para maior legibilidade
        grid on;
    
        % Destacar a categoria prevista no gráfico
        hold on;
        bar(predicted_Category, prob_log(predicted_Category), 'FaceColor', 'r', 'EdgeColor', 'k');
        legend('Log(P(C|F))', 'Categoria Prevista', 'Location', 'Best');
        hold off;
    
        % Finalizar waitbar
        waitbar(1, h, 'Gráficos concluídos!');
        pause(1);
        close(h);
    end
end
