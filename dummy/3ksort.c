#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 10000   

int compare(const void *a, const void *b) {
    return (*(int*)a - *(int*)b);
}

int main() {
    printf("Inizio ordinamento...\n");
    int arr[N];

    srand(time(NULL));

    for (int i = 0; i < N; i++) {
        arr[i] = rand() % 10000;   
    }

    qsort(arr, N, sizeof(int), compare);


    return 0;
}

