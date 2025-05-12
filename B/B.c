#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define MAX_PATH_LEN 1000
#define MAX_CHILDREN 100

typedef struct {
    double sum;
    int path[MAX_PATH_LEN];
    int pathLength;
} Result;

typedef struct {
    double value;
    int num_children;
    int children[MAX_CHILDREN];
} Node;

Result computePaths(Node* tree, int idx, int depth);

// Versão paralela principal
Result computePathsParallel(Node* tree, int idx) {
    Result best = {0};

    #pragma omp parallel
    {
        #pragma omp single
        {
            best = computePaths(tree, idx, 0);
        }
    }
    return best;
}

// Função com paralelismo recursivo controlado
Result computePaths(Node* tree, int idx, int depth) {
    Result res = {0};
    if (tree[idx].num_children == 0) {
        res.sum = tree[idx].value;
        res.path[0] = idx;
        res.pathLength = 1;
        return res;
    }

    Result* results = malloc(tree[idx].num_children * sizeof(Result));

    #pragma omp taskgroup
    for (int i = 0; i < tree[idx].num_children; ++i) {
        int childIdx = tree[idx].children[i];

        #pragma omp task shared(results) firstprivate(i, childIdx)
        {
            results[i] = computePaths(tree, childIdx, depth + 1);
        }
    }

    // Espera as tasks terminarem
    #pragma omp taskwait

    // Encontrar o melhor resultado
    int maxIndex = 0;
    double maxSum = results[0].sum;
    for (int i = 1; i < tree[idx].num_children; ++i) {
        if (results[i].sum > maxSum) {
            maxSum = results[i].sum;
            maxIndex = i;
        }
    }

    Result best = results[maxIndex];

    res.sum = tree[idx].value + best.sum;
    res.path[0] = idx;
    for (int i = 0; i < best.pathLength; ++i) {
        res.path[i + 1] = best.path[i];
    }
    res.pathLength = best.pathLength + 1;

    free(results);
    return res;
}

int main() {
    int N;
    scanf("%d", &N);

    Node* tree = malloc(N * sizeof(Node));
    for (int i = 0; i < N; ++i) {
        scanf("%lf %d", &tree[i].value, &tree[i].num_children);
        for (int j = 0; j < tree[i].num_children; ++j) {
            scanf("%d", &tree[i].children[j]);
            tree[i].children[j]--; // base 0
        }
    }

    Result finalRes = computePathsParallel(tree, 0);
    printf("Max Sum: %.2lf\n", finalRes.sum);
    printf("Path: ");
    for (int i = 0; i < finalRes.pathLength; ++i) {
        printf("%d ", finalRes.path[i] + 1);
    }
    printf("\n");

    free(tree);
    return 0;
}
