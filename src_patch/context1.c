/*
 * WASM Design Choice:
 *
 * In the original UNIX benchmark, inter-process communication via pipes and
 * context switching via fork() simulate a ping-pong exchange. However, in a
 * WebAssembly environment (Emscripten with pthread support), pipes and fork()
 * are either unsupported or poorly emulated, leading to errors such as
 * “Bad file descriptor” or “Resource temporarily unavailable.” 
 * [despite single pipe communication like in pipe.c]
 *
 * To achieve 100% compatibility and robust behavior, we replaced pipes with
 * an in-memory buffer protected by a pthread mutex and two condition variables.
 * This approach:
 *   1. Uses only POSIX threads (pthread_create/join), which Emscripten supports
 *      when compiled with -s USE_PTHREADS=1 and PROXY_TO_PTHREAD=1.
 *   2. Provides explicit, deterministic synchronization for the ping-pong
 *      exchange, eliminating kernel buffering unpredictability.
 *   3. Avoids syscalls that are unavailable or unreliable in WebAssembly,
 *      while preserving the original benchmark’s intent of measuring
 *      context-switch overhead in a controlled loop.
 */


#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>


static unsigned long iter = 0;
static unsigned long buffer = 0;
static int data_ready = 0;

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond_master = PTHREAD_COND_INITIALIZER;
pthread_cond_t cond_slave = PTHREAD_COND_INITIALIZER;

void report() {
    fprintf(stderr, "COUNT|%lu|1|lps\n", iter);
    exit(0);
}

void *slave_thread(void *arg) {
    (void)arg;
    while (1) {
        pthread_mutex_lock(&lock);

        while (!data_ready)
            pthread_cond_wait(&cond_slave, &lock);

        if (buffer != iter) {
            fprintf(stderr, "Slave sync error: expect %lu, got %lu\n", iter, buffer);
            pthread_mutex_unlock(&lock);
            exit(2);
        }

        buffer = iter;
        data_ready = 0;

        pthread_cond_signal(&cond_master);
        pthread_mutex_unlock(&lock);
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s duration\n", argv[0]);
        return 1;
    }

    int duration = atoi(argv[1]);
    pthread_t slave;

    // Setup termination after duration seconds
    wake_me(duration, report);

    // Start slave thread
    if (pthread_create(&slave, NULL, slave_thread, NULL) != 0) {
        perror("pthread_create");
        return 1;
    }

    while (1) {
        pthread_mutex_lock(&lock);

        buffer = iter;
        data_ready = 1;
        pthread_cond_signal(&cond_slave);

        while (data_ready)
            pthread_cond_wait(&cond_master, &lock);

        if (buffer != iter) {
            fprintf(stderr, "Master sync error: expect %lu, got %lu\n", iter, buffer);
            pthread_mutex_unlock(&lock);
            exit(2);
        }

        iter++;
        pthread_mutex_unlock(&lock);
    }

    pthread_join(slave, NULL); // Non raggiunto, ma buono stile
    return 0;
}
