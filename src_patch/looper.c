#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <emscripten/emscripten.h>

unsigned long iter = 0;
char **cmd_argv;
int cmd_argc;

void report(void)
{
    fprintf(stderr, "COUNT|%lu|60|lpm\n", iter);
    exit(0);
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
        exit(1);
    }

    duration = atoi(argv[1]);
    if (duration < 1) {
        fprintf(stderr, "Duration must be at least 1 second.\n");
        exit(1);
    }

    cmd_argc = argc - 2;
    cmd_argv = &argv[2];

    iter = 0;
    wake_me(duration, report);

    while (1) {
        pthread_t thread;
        if (pthread_create(&thread, NULL, run_command, NULL) != 0) {
            fprintf(stderr, "Thread creation failed at iteration %lu\n", iter);
            perror("Reason");
            exit(2);
        }

        pthread_join(thread, NULL);
        iter++;
    }

    return 0;
}
