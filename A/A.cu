#include "A.h"
#include <cub/cub.cuh>
#include <limits.h>
#include <time.h>

__global__ void calcular_distancia(Point* all_points, char* all_labels, float* all_distances, char* label_distances, int total_points, int k, Point to_evaluate){
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if(i < total_points){
        all_distances[i] = ((to_evaluate.x - all_points[i].x) * ((to_evaluate.x - all_points[i].x))) + ((to_evaluate.y - all_points[i].y) * (to_evaluate.y - all_points[i].y));
        label_distances[i] = all_labels[i];
    }
}

int unindo_groups(Point** all_points, char** all_labels, Group* groups, int n_groups){
    int total_points = 0;
    for(int i = 0; i < n_groups; i++) total_points += groups[i].length;

    *all_points = (Point*)malloc(sizeof(Point) * total_points);
    *all_labels = (char*)malloc(sizeof(char) * total_points);

    int indice = 0;
    for(int i = 0; i < n_groups; i++){
        for(int j = 0; j < groups[i].length; j++){
            (*all_points)[indice] = groups[i].points[j];
            (*all_labels)[indice] = groups[i].label;
            indice++;
        }
    }
    return total_points;
}

void ordenar_distancias(float* all_distances, float* sorted_distances, char* all_labels, char* sorted_labels, int total_distances){
    void* aux = NULL;
    size_t aux_bytes = 0;
    
    cub::DeviceRadixSort::SortPairs(aux, aux_bytes, all_distances, sorted_distances, all_labels, sorted_labels, total_distances);

    cudaMalloc(&aux, aux_bytes);

    cub::DeviceRadixSort::SortPairs(aux, aux_bytes, all_distances, sorted_distances, all_labels, sorted_labels, total_distances);
    cudaFree(aux);

}

char calcular_mais_frequente(char* labels, int k){
    int freq[256] = {0};
    for(int i = 0; i < k; i++){
        unsigned char indice = (unsigned char)labels[i];
        freq[indice]++;
    }

    char mais_frequente = 0;
    int max_freq = INT_MIN;
    for(int i = 0; i <256; i++){
        if(freq[i] > max_freq){
            max_freq = freq[i];
            mais_frequente = char(i);
        }
    }
    return mais_frequente;
}

char knn(Point* all_points, char* all_labels, int total_points, int k, Point to_evaluate){
    float *dev_all_distances;
    char *dev_label_distances;
    Point *dev_all_points;
    char *dev_all_labels;
    
    cudaMalloc((void**)&dev_all_points, total_points * sizeof(Point));

    cudaMalloc((void**)&dev_all_labels, total_points * sizeof(char));

    cudaMalloc((void**)&dev_all_distances, total_points * sizeof(float));

    cudaMalloc((void**)&dev_label_distances, total_points * sizeof(char));

    cudaMemcpy(dev_all_points, all_points, total_points * sizeof(Point), cudaMemcpyHostToDevice);

    cudaMemcpy(dev_all_labels, all_labels, total_points * sizeof(char), cudaMemcpyHostToDevice);

    int threads = 128;
    int blocks = (total_points + (threads - 1)) / threads;

    calcular_distancia<<<blocks, threads>>>(dev_all_points, dev_all_labels, dev_all_distances, dev_label_distances, total_points, k, to_evaluate);
    cudaDeviceSynchronize();

    float* dev_sorted_distances;
    char* dev_sorted_labels;

    cudaMalloc(&dev_sorted_distances, total_points * sizeof(float));

    cudaMalloc(&dev_sorted_labels, total_points * sizeof(char));

    ordenar_distancias(dev_all_distances, dev_sorted_distances, dev_label_distances, dev_sorted_labels, total_points);

    char* k_menores_labels = (char*)malloc(k * sizeof(char));
    cudaMemcpy(k_menores_labels, dev_sorted_labels, k * sizeof(char), cudaMemcpyDeviceToHost);

    char resultado = calcular_mais_frequente(k_menores_labels, k);
    return resultado;
}

int main(){
    int n_groups = parse_number_of_groups();
    
    Group *groups = (Group *) malloc(sizeof(Group) * n_groups);
    
    for (int i = 0; i < n_groups; i++) {
        groups[i] = parse_next_group();
    }
    
    
    int k = parse_k();
    Point to_evaluate = parse_point();
    
    Point *all_points;
    char *all_labels;
    int total_points = unindo_groups(&all_points, &all_labels, groups, n_groups);
    printf("%c", knn(all_points, all_labels, total_points, k, to_evaluate));
}