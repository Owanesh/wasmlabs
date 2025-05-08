#if defined(__EMSCRIPTEN__)
#include <emscripten.h>
#include <stdlib.h>

void wake_me(int seconds, void (*func)());

// Global function pointer
static void (*callback_func)() = NULL;

void call_callback_func(void *arg)
{
	if (callback_func)
	{
		callback_func(); // calls report()
	}
}

void wake_me(int seconds, void (*func)())
{
	callback_func = func;
	emscripten_set_timeout(call_callback_func, seconds * 1000, NULL);
}

#elif defined(__wasix__) || defined(__wasi__)
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>

void wake_me(int seconds, void (*func)());

// Thread wrapper for WASIX with infinite loop and debug output
static void* wasix_timer_thread(void* arg) {
    struct {
        int seconds;
        void (*func)();
    } *args = arg;

    printf("[wake_me] Timer thread started. Interval: %d seconds\n", args->seconds);

    while (1) {
        sleep(args->seconds);
        if (args->func) {
            printf("[wake_me] Triggering callback...\n");
            args->func();
        } else {
            printf("[wake_me] No callback function set.\n");
        }
    }

    free(arg); // This will never be reached, but left for completeness
    return NULL;
}

void wake_me(int seconds, void (*func)()) {
    pthread_t tid;
    void* args = malloc(sizeof(struct { int seconds; void (*func)(); }));
    ((struct { int seconds; void (*func)(); }*)args)->seconds = seconds;
    ((struct { int seconds; void (*func)(); }*)args)->func = func;

    if (pthread_create(&tid, NULL, wasix_timer_thread, args) != 0) {
        perror("[wake_me] Failed to create timer thread");
        free(args);
    } else {
        pthread_detach(tid);
        printf("[wake_me] Timer thread launched.\n");
    }
}
#endif