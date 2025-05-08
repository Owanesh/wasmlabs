#include <stdio.h>
#include <pthread.h>

void *thread_routine(void *arg)
{
    printf("[OK ] Enter thread 🧵👨‍💻\n");
    pthread_exit(NULL);
    return NULL;
}

int main(int argc, char** argv)
{
    pthread_t tid;

    if (0 != pthread_create(&tid, NULL, thread_routine, NULL)) {
        printf("Failed to create thread ❌\n");
    }

    if (0 != pthread_join(tid, NULL)) {
        printf("Failed to join thread %d. 😞\n", tid);
    }

    printf("Exit 👋\n");

    return 0;
}
