data_set=[  "WE", "Roubada";
            "A LOT", "Não roubada";
            "asdasdf", "Roubada";
            "MOOORE", "Não roubada";
            "MOOOOOOORE", "NEED"];

treino = data_set(1:3,:);
teste = data_set(4,:);
classes = unique(data_set(:, 2));
model = struct();
