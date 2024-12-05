data_set = load("Dataset.m");

treino = data_set(1:3,:);
teste = data_set(4,:);
classes = categorical(data_set(1:end,2:end)')
classes_unicas = unique(classes)
model = struct();