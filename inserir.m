function [filtro] = inserir(filtro,elemento,k)
    chave=elemento;     
    for i = 1:k         
        chave = [chave num2str(i)];      
        hash_code = string2hash(chave);      
        indice = mod(hash_code,length(filtro))+1;   
        filtro(indice) = 1;     
    end
end
