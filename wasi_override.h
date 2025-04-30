// src/wasi_override.h
#ifndef WASI_OVERRIDE_H
#define WASI_OVERRIDE_H

// tipi di processo
typedef int pid_t;
static pid_t getpid(void)  { return 1; }
static pid_t getppid(void) { return 1; }

// timer e segnale
static unsigned int alarm(unsigned int seconds) { (void)seconds; return 0; }
//static void signal(int sig, void (*handler)(int)) { (void)sig; (void)handler; }

// busy-wait wake_me
#include <time.h>
static void wake_me(int seconds, void (*handler)(int)) {
    struct timespec start, now;
    clock_gettime(CLOCK_REALTIME, &start);
    do {
        clock_gettime(CLOCK_REALTIME, &now);
    } while ((now.tv_sec - start.tv_sec) < seconds);
    handler(0);
}

#endif // WASI_OVERRIDE_H
