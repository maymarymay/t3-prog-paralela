#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <cuda_runtime.h>

// definindo um INF
#define INF 999999

// alocando matriz
int** aloca_matriz(int n) 
{
    int** matriz = (int**)malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++) 
    {
        matriz[i] = (int*)malloc(n * sizeof(int));
    }
    return matriz;
}

// liberando matriz
void libera_matriz(int** matriz, int n) 
{
    for (int i = 0; i < n; i++) 
    {
        free(matriz[i]);
    }
    free(matriz);
}

// lendo arquivo
int** le_grafo(const char *nome_arquivo, int *n_out) 
{
    FILE *arquivo = fopen(nome_arquivo, "r");
    if (arquivo == NULL) 
    {
        printf("ERRO em abrir o arquivo %s\n", nome_arquivo);
        return NULL;
    }

    int n;
    fscanf(arquivo, "%d", &n);
    *n_out = n;

    printf("lendo... (grafo com %d vertices)\n", n);
    int** g_adj = aloca_matriz(n);

    for (int i = 0; i < n; i++) 
    {
        for (int j = 0; j < n; j++) 
        {
            char buffer[64];
            fscanf(arquivo, "%s", buffer);

            if (buffer[0] == 'I' || buffer[0] == 'i') 
            {
                g_adj[i][j] = INF;
            } else {
                g_adj[i][j] = atoi(buffer);
            }
        }
    }

    fclose(arquivo);
    printf("LIDO :D\n");
    return g_adj;
}

// salvando o resultado da matriz (de um vetor 1D)
void salva_matriz(int *vetor, int n, const char *nome_arquivo) 
{
    FILE *arquivo = fopen(nome_arquivo, "w");
    if (arquivo == NULL) {
        printf("ERRO ao criar o arquivo %s\n", nome_arquivo);
        return;
    }
    
    for (int i = 0; i < n; i++) 
    {
        for (int j = 0; j < n; j++) 
        {
            if (vetor[i * n + j] == INF) 
            {
                fprintf(arquivo, "INF ");
            } else {
                fprintf(arquivo, "%d ", vetor[i * n + j]);
            }
        }
        fprintf(arquivo, "\n");
    }
    fclose(arquivo);
    printf("SALVO :D (em: %s)\n", nome_arquivo);
}

// muda matriz 2D pra vetor 1D (o cuda precisa)
int *matriz_para_vetor(int **matriz, int n) 
{
    int *vetor = (int *)malloc(n * n * sizeof(int));
    for (int i = 0; i < n; i++) 
    {
        for (int j = 0; j < n; j++) 
        {
            vetor[i * n + j] = matriz[i][j];
        }
    }
    return vetor;
}

// Kernel para o passo K do Floyd-Warshall
__global__ void floyd_kernel_simples(int *dist, int n, int k) 
{
    // mapeamento simples: cada thread processa um par (i, j)
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (idx < n * n) 
    {
        // converte o indice 1D para coordenadas 2D (i, j)
        int i = idx / n;
        int j = idx % n;

        // acessa as distancias
        int dist_ik = dist[i * n + k];
        int dist_kj = dist[k * n + j];
        int dist_ij = dist[i * n + j];

        // se o caminho i -> k -> j nao for infinito
        if (dist_ik != INF && dist_kj != INF) 
        {
            int novo_caminho = dist_ik + dist_kj;
            
            // tenta melhorar a dist
            if (novo_caminho < dist_ij)
            {
                dist[i * n + j] = novo_caminho;
            }
        }
    }
}

// algoritimo principal

double executa_floyd_cuda(int **matriz_entrada, int n, int **resultado) 
{
    int tamanho_bytes = n * n * sizeof(int);

    printf("\npreparando...\n");

    // prepara dados no CPU
    int *h_dist = matriz_para_vetor(matriz_entrada, n);

    // aloca memoria na GPU
    int *d_dist;
    cudaMalloc(&d_dist, tamanho_bytes);

    // copia dados da CPU para a GPU
    cudaMemcpy(d_dist, h_dist, tamanho_bytes, cudaMemcpyHostToDevice);

    //configurando threads e blocos (Simples: 1D)
    int threads = 256;
    int blocks = (n * n + threads - 1) / threads;
    dim3 threadsPerBlock = dim3(threads, 1);
    dim3 numBlocks = dim3(blocks, 1);

    printf("config: %d blocos, %d threads por bloco\n", numBlocks.x, threadsPerBlock.x);

    // medindo o tempo
    cudaEvent_t inicio, fim;
    cudaEventCreate(&inicio);
    cudaEventCreate(&fim);
    cudaEventRecord(inicio);

    // loop principal (Passos K)
    for (int k = 0; k < n; k++) {
        // executando o kernel para o passo k
        floyd_kernel_simples<<<numBlocks, threadsPerBlock>>>(d_dist, n, k);
        
        // Sincroniza (garante que todos os passos anteriores terminaram)
        cudaDeviceSynchronize(); 
    }

    cudaEventRecord(fim);
    cudaEventSynchronize(fim);

    // calculando tempo
    float tempo_ms = 0;
    cudaEventElapsedTime(&tempo_ms, inicio, fim);
    double tempo_segundos = tempo_ms / 1000.0;

    printf("CONCLUIDO :D\n");

    // copiando o resultado de volta pra CPU
    cudaMemcpy(h_dist, d_dist, tamanho_bytes, cudaMemcpyDeviceToHost);

    // retornando resultado (vetor 1D)
    *resultado = (int *)malloc(tamanho_bytes);
    memcpy(*resultado, h_dist, tamanho_bytes);

    // liberando
    cudaFree(d_dist);
    cudaEventDestroy(inicio);
    cudaEventDestroy(fim);
    free(h_dist);

    return tempo_segundos;
}

// main

int main(int argc, char *argv[]) {
    printf("==versao cuda==\n\n");

    if (argc < 2) 
    {
        printf("%s <arquivo_grafo> [arquivo_saida]\n", argv[0]);
        return 1;
    }

    // detectando GPU
    int count;
    cudaGetDeviceCount(&count);
    if (count == 0) 
    {
        printf("ERRO encontrando GPU\n");
        return 1;
    }
    
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    printf("GPU: %s\n", prop.name);
    printf("memoria global: %zu MB\n\n", prop.totalGlobalMem / (1024 * 1024));

    // lendo grafo
    int n;
    int **matriz_entrada = le_grafo(argv[1], &n);
    if (matriz_entrada == NULL) 
    {
        return 1;
    }

    // executando na GPU
    int *distancias_gpu = NULL;
    double tempo_gpu = executa_floyd_cuda(matriz_entrada, n, &distancias_gpu);

    printf("\nRESULTADOS:\n");
    printf("vertices: %d\n", n);
    printf("tempo: %.6f segundos\n", tempo_gpu);

    // salvando
    if (argc >= 3) {
        salva_matriz(distancias_gpu, n, argv[2]);
    }

    // free
    free(distancias_gpu);
    libera_matriz(matriz_entrada, n);

    printf("\nfim do cuda\n");
    return 0;
}