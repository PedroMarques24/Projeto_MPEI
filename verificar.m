function [res] = verificar(filtro,elemento,k)
    chave=elemento;     
    for i = 1:k         
        chave = [chave num2str(i)];      
        hash_code = string2hash(chave);      
        indice = mod(hash_code,length(filtro))+1;   
        bits(i)=filtro(indice);         
    end
    res=all(bits);
end
