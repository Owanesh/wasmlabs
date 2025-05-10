#if defined(__EMSCRIPTEN__) || defined(__wasix__) || defined(__wasi__)
#ifndef WASITIME_H
#define WASITIME_H

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>  // for sleep()

typedef void (*callback_t)(void);

typedef struct {
    int seconds;
    callback_t cb;
} TimerArgs;

void* timer_thread(void* arg) {
    TimerArgs* args = (TimerArgs*)arg;

    sleep(args->seconds);

    if (args->cb) {
        args->cb();
    }

    free(args);
    return NULL;
}

void wake_me(int seconds, callback_t cb) {
    TimerArgs* args = malloc(sizeof(TimerArgs));
    args->seconds = seconds;
    args->cb = cb;

    pthread_t tid;
    if (pthread_create(&tid, NULL, timer_thread, args) == 0) {
        pthread_detach(tid);  // Let it clean up on its own
    } else {
        free(args);
    }
}

#endif
#endif
