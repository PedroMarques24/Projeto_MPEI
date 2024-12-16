% ------- Bloom filter -> Teste --------
lista_de_produtos = readtable("Lista_de_compras.csv");
disp(lista_de_produtos);
run('C:\Github\Projetos\Projeto_MPEI\Bloom_Filter.m');
teste_bloom_filter = intersect(produtos.Name, lista_de_produtos.Name);
if isempty(teste_bloom_filter)
    fprintf("\n Passou no teste!\n")
else
    fprintf("\n Não passou no teste!\n")
end

%% --------- MinHash -> Teste ----------

run('C:\Github\Projetos\Projeto_MPEI\Minhash.m');

elementos=[];
for x = 1:numel(users_parecidos)
    produtos = data(data.UserID == alguem(users_parecidos(x)), 'Name');
    for produto = 1:numel(produtos)
        elementos=[elementos produtos{produto,1}];
    end
end

teste_do_minhash = intersect(recomendados,elementos);

if numel(teste_do_minhash) == numel(recomendados)
    fprintf("\nPassou no teste! \n")
else 
    fprintf("\n Não passou no teste! \n")
    
end