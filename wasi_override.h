#ifndef WASI_OVERRIDE_H
#define WASI_OVERRIDE_H

#ifdef __wasm__
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <time.h>
#include <unistd.h>

extern volatile unsigned long iter;

static void (*callback_func)(void);

void* timer_thread(void* arg) {
    int seconds = *(int*)arg;
    sleep(seconds);
    callback_func();
    return NULL;
}

void wake_me(int seconds, void (*func)(void)) {
    pthread_t tid;
    callback_func = func;

    if (pthread_create(&tid, NULL, timer_thread, &seconds) != 0) {
        fprintf(stderr, "Failed to create timer thread\n");
        func(); // fallback
        return;
    }

    pthread_detach(tid);
}


#endif


#ifndef __wasm__
#include <sys/types.h>
#include <sys/wait.h>
#endif

#endif // WASI_OVERRIDE_H
