#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>

unsigned long iter = 0;

void* quick_exit_thread(void* arg) {
    pthread_exit(NULL);
}

void report() {
    fprintf(stderr, "COUNT|%lu|1|lps\n", iter);
    exit(0);
}

int main(int argc, char* argv[]) {
    int duration;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s duration\n", argv[0]);
        return 1;
    }

    duration = atoi(argv[1]);
    if (duration < 1) {
        fprintf(stderr, "Duration must be at least 1 second.\n");
        return 1;
    }

    iter = 0;
    wake_me(duration, report);  
    while (1) {
        pthread_t thread;
        int rc = pthread_create(&thread, NULL, quick_exit_thread, NULL);
        if (rc != 0) {
            fprintf(stderr, "Thread creation failed at iteration %lu\n", iter);
            perror("Reason");
            exit(2);
        }

        pthread_join(thread, NULL);  
        iter++;
    }

    return 0;
}
