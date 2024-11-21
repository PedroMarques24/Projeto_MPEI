data_set=[  "WE", "eletronico", "uso diário";
            "A LOT", "comestível", "doce";
            "asdasdf", "comestível", "salgado";
            "MOOORE", "eletronico", "entretenimento";
            "MOOOOOOORE", "brinquedo", "entretenimento"];

treino = data_set(1:3,:);
teste = data_set(4,:);
classes = categorical(data_set(1:end,2:end)')
classes_unicas = unique(classes)
model = struct();