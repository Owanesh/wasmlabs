/*
 * WASM STRATEGIC DECISION:
 *
 * This file is a WebAssembly-compatible reimplementation of the original `looper.c`
 * benchmark from the BYTE UNIX Benchmarks suite, originally designed to repeatedly
 * spawn and wait for child processes via fork()/execvp() in a loop.
 *
 * Since Emscripten and the WebAssembly System Interface (WASI) do not support traditional
 * Unix process management such as fork() and exec(), the implementation strategy had
 * to be rethought to maintain benchmark fidelity while complying with WASM limitations.
 *
 * Key decisions and adaptations:
 *
 * 1. FORK/EXEC REPLACEMENT:
 *    The original benchmark used fork() + execvp() to spawn a command-line tool per loop.
 *    In WASM, this is replaced with POSIX threads (`pthread_create`) and the actual command
 *    is executed using a JavaScript shell wrapper (`spawnSync`) via Emscripten's EM_ASM macro.
 *    This allows invoking external shell commands from within WASM when running under Node.js.
 *
 * 2. REPORTING STRATEGY:
 *    Instead of calling `exit()` inside the `report()` function (as in the original),
 *    we now set a shared flag (`stop`) which cleanly breaks the loop in `main()`.
 *    This avoids triggering `ExitStatus` exceptions in Node.js, which would otherwise
 *    terminate the entire runner script prematurely. Useful for 20x iterations.
 *
 */



#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <emscripten/emscripten.h>

unsigned long iter = 0;
char **cmd_argv;
int cmd_argc;
volatile int stop = 0;  // 🔧 flag per fermare il ciclo

void report(void)
{
    stop = 1;  // 🔧 segnala lo stop, non esce subito
}

void* run_command(void* arg)
{
    size_t cmdlen = 0;
    for (int i = 0; i < cmd_argc; i++)
        cmdlen += strlen(cmd_argv[i]) + 1;

    char *cmd_str = malloc(cmdlen + 1);
    cmd_str[0] = '\0';
    for (int i = 0; i < cmd_argc; i++) {
        strcat(cmd_str, cmd_argv[i]);
        if (i < cmd_argc - 1)
            strcat(cmd_str, " ");
    }

    EM_ASM({
        const cmd = UTF8ToString($0);
        const { spawnSync } = require('child_process');
        const result = spawnSync(cmd, { shell: true });
        if (result.status !== 0) {
            console.error("Command failed:", cmd);
            if (result.stderr) process.stderr.write(result.stderr.toString());
        }
    }, cmd_str);

    free(cmd_str);
    return NULL;
}

int main(int argc, char* argv[])
{
    int duration;

    if (argc < 3) {
        fprintf(stderr, "Usage: %s duration command [args...]\n", argv[0]);
        return 1;
    }

    duration = atoi(argv[1]);
    if (duration < 1) {
        fprintf(stderr, "Duration must be at least 1 second.\n");
        return 1;
    }

    cmd_argc = argc - 2;
    cmd_argv = &argv[2];

    iter = 0;
    wake_me(duration, report);  // 🔧 imposta la sveglia

    while (!stop) {  // 🔧 esce solo quando wake_me chiama report
        pthread_t thread;
        if (pthread_create(&thread, NULL, run_command, NULL) != 0) {
            fprintf(stderr, "Thread creation failed at iteration %lu\n", iter);
            perror("Reason");
            return 2;
        }

        pthread_join(thread, NULL);
        iter++;
    }

    // 🔧 stampa risultato dopo uscita naturale dal ciclo
    fprintf(stderr, "COUNT|%lu|60|lpm\n", iter);
    return 0;
}
