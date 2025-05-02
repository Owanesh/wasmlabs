#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

void* thread_function(void* arg) {
    printf("Thread is running\n");
    return NULL;
}

int main() {
    pthread_t thread;
    
    if (pthread_create(&thread, NULL, thread_function, NULL) != 0) {
        printf("Failed to create thread\n");
        return 1;
    }
    
    pthread_join(thread, NULL);
    
    printf("Thread completed\n");
    return 0;
}
