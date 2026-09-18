# Objetivos
• Implementar uma aplicação em CUDA e C capaz de calcular todos os pares de caminhos mínimos(APSP) em um grafo ponderado.
• Avaliar o desempenho da versão GPU em comparação com uma versão sequencial em CPU.
• Realizar experimentos em uma máquina equipada com GPU NVIDIA com pelo menos 16 GB de memória

como rodar T3

> python3 gerar_grafos.py [gera todos os arquivos]

> gcc -o seq sequencial.c [compila sequencial]

(é bom ter pasta input e output)
> ./seq input/grafo_[VERTICES]_[DENSIDADE].txt output/escolhe_nome.txt

ex: ./seq input/grafo_1024_25.txt output/resultado_seq_1024_25.txt

> nvcc -o cuda APSP.cu [compila cuda]

> ./cuda input/grafo_[VERTICES]_[DENSIDADE].txt output/escolhe_nome.txt

ex: ./cuda input/grafo_1024_25.txt output/resultado_cuda_1024_25.txt
