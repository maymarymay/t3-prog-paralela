import random
import os

def criar_grafo_simples(num_v, densidade, peso_min=1, peso_max=100):

    # inicia a matriz com 'INF'
    matriz = [['INF' for _ in range(num_v)] for _ in range(num_v)]
    for i in range(num_v):
        for j in range(num_v):
            if i == j:
                matriz[i][j] = 0
            # add aresta com densidade 
            elif random.random() < densidade:
                peso = random.randint(peso_min, peso_max)
                matriz[i][j] = peso
            # se n tiver mantém 'INF'

    return matriz

def salvar_matriz(matriz, nome_arquivo):
    # salva matriz
    num_v = len(matriz)
    with open(nome_arquivo, 'w') as f:
        f.write(f"{num_v}\n")
        
        for linha in matriz:
            linha_str = ' '.join(str(valor) for valor in linha)
            f.write(linha_str + '\n')
    
    print(f"arquivo salvo: {nome_arquivo}")

def main():
    # criando TODOS os grafos
    random.seed(42)
    tamanhos = [1024, 2048, 3072, 4096]
    densidades = [0.25, 0.50, 0.75]
    os.makedirs('input', exist_ok=True)
    
    for tamanho in tamanhos:
        for densidade in densidades:
            nome_arquivo = f"input/grafo_{tamanho}_{int(densidade*100)}.txt"
            
            print(f"fazendo: {tamanho} vertices, {int(densidade*100)}% densidade")

            matriz = criar_grafo_simples(tamanho, densidade)
            salvar_matriz(matriz, nome_arquivo)
    
    print("\nfim")

if __name__ == "__main__":
    main()