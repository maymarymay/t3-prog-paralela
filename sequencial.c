#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

// definindo um INF
#define INF 999999

// alocando matriz N x N
int** aloca_matriz(int n) 
{
    int** matriz = (int**)malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++) 
    {
        matriz[i] = (int*)malloc(n * sizeof(int));
    }
    return matriz;
}

// liberando matriz N x N
void libera_matriz(int** matriz, int n) 
{
    for (int i = 0; i < n; i++) 
    {
        free(matriz[i]);
    }
    free(matriz);
}

// lendo a matriz de um arquivo
int** le_matriz_grafo(const char *nome_arquivo, int *n_out) 
{
    FILE *arquivo = fopen(nome_arquivo, "r");
    if (arquivo == NULL) 
    {
        printf("ERRO em ler o arquivo %s\n", nome_arquivo);
        return NULL;
    }

    int n;
    fscanf(arquivo, "%d", &n);
    *n_out = n;

    printf("lendo... (grafo com %d vertices)\n", n);
    int** matriz = aloca_matriz(n);

    for(int i = 0; i < n; i++) 
    {
        for(int j = 0; j < n; j++) 
        {
            char buffer[64]; 
            fscanf(arquivo, "%s", buffer);

            if(buffer[0] == 'I' || buffer[0] == 'i') 
            {
                matriz[i][j] = INF;
            } else {
                matriz[i][j] = atoi(buffer);
            }
        }
    }

    fclose(arquivo);
    printf("LIDO :D\n");
    return matriz;
}

void salva_resultado(int **matriz, int n, const char *nome_arquivo) 
{
    FILE *arquivo = fopen(nome_arquivo, "w");
    if (arquivo == NULL) {
        printf("ERRO em criar o arquivo %s\n", nome_arquivo);
        return;
    }

    printf("salvando... (em %s)\n", nome_arquivo);
    
    for(int i = 0; i < n; i++) 
    {
        for(int j = 0; j < n; j++) 
        {
            if (matriz[i][j] == INF) 
            {
                fprintf(arquivo, "INF ");
            } else {
                fprintf(arquivo, "%d ", matriz[i][j]);
            }
        }
        fprintf(arquivo, "\n");
    }

    fclose(arquivo);
    printf("SALVO :D\n");
}

// função principal
int **floyd_warshall_sequencial(int **dist_inicial, int n) 
{
    
    // criando copia da matriz
    int **dist = aloca_matriz(n);
    for (int i = 0; i < n; i++) 
    {
        for (int j = 0; j < n; j++) 
        {
            dist[i][j] = dist_inicial[i][j];
        }
    }

    printf("\nexecutando...\n");

    // algoritmo Floyd-Warshall
    for (int k = 0; k < n; k++) // vertice intermediario
    { 
        for (int i = 0; i < n; i++) // vertice de origem
        { 
            for (int j = 0; j < n; j++) // vertice de destino
            { 
                
                // aqui pra nao somar com INF 
                if (dist[i][k] != INF && dist[k][j] != INF) 
                {
                    int novo_caminho = dist[i][k] + dist[k][j];
                    if (novo_caminho < dist[i][j]) 
                    {
                        dist[i][j] = novo_caminho;
                    }
                }
            }
        }
    }

    printf("EXECUTADO :D\n");
    return dist;
}


int main(int argc, char *argv[]) 
{
    printf("==versao CPU sequencial==\n\n");

    if (argc < 2) 
    {
        printf("%s <arquivo_grafo> [arquivo_saida]\n", argv[0]);
        return 1;
    }

    int n;
    // lendo o grafo
    int **matriz_entrada = le_matriz_grafo(argv[1], &n);
    if (matriz_entrada == NULL) 
    {
        return 1;
    }

    // executando e medindo o tempo
    clock_t inicio = clock();
    int **distancias = floyd_warshall_sequencial(matriz_entrada, n);
    clock_t fim = clock();
    
    double tempo_execucao = ((double)(fim - inicio)) / CLOCKS_PER_SEC;
    
    if (distancias == NULL) 
    {
        libera_matriz(matriz_entrada, n);
        return 1;
    }

    printf("\nRESULTADOS:\n");
    printf("vertices: %d\n", n);
    printf("tempo: %.6f segundos\n", tempo_execucao);

    // salvando
    if (argc >= 3) 
    {
        char comando[100];
        sprintf(comando, "mkdir -p output");
        system(comando);
        salva_resultado(distancias, n, argv[2]);
    }

    // liberando memoria
    libera_matriz(distancias, n);
    libera_matriz(matriz_entrada, n);

    printf("\nfim do sequencial\n");
    return 0;
}