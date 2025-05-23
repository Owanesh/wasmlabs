/**
 * @file wasitime.h
 * @brief Timer utility using POSIX threads, designed for Emscripten/WebAssembly compatibility.
 *
 * This header provides a simple mechanism to schedule a callback function
 * to be executed after a delay (in seconds), implemented using pthreads.
 * It is suitable for use in environments such as Emscripten, where standard
 * Unix signals or timers may not be available.
 */

#ifndef WASITIME_H
#define WASITIME_H

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>   


/**
 * @typedef callback_t
 * @brief Function pointer type for timer callbacks.
 *
 * Defines the type for a callback function that takes no arguments and returns void.
 */
typedef void (*callback_t)(void);

/**
 * @struct TimerArgs
 * @brief Internal structure to pass parameters to the timer thread.
 */
typedef struct {
    int seconds;
    callback_t cb;
} TimerArgs;



/**
 * @brief Timer thread function.
 *
 * This function sleeps for the specified number of seconds and then
 * calls the provided callback function. It is intended to be run in a detached thread.
 *
 * @param arg A pointer to a TimerArgs struct containing the timer configuration.
 * @return NULL
 */
void* timer_thread(void* arg) {
    TimerArgs* args = (TimerArgs*)arg;

    sleep(args->seconds);

    if (args->cb) {
        args->cb();
    }

    free(args);
    return NULL;
}


/**
 * @brief Starts a detached timer that calls a callback after a delay.
 *
 * This function launches a new thread that sleeps for the specified number
 * of seconds and then invokes the given callback function. The thread is detached
 * and will clean itself up automatically.
 *
 * @param seconds The number of seconds to wait before executing the callback.
 * @param cb The callback function to invoke after the delay.
 */
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
