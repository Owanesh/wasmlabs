#include <stdio.h>
#include <pthread.h>  
#include <stdlib.h>

/**
 * @brief Function executed by the thread.
 *
 * This function prints a message when the thread is entered, then
 * calls `pthread_exit()` to terminate the thread properly.
 *
 * @param arg Argument passed to the thread, not used in this case.
 * @return Always returns `NULL`, as required by `pthread_exit`.
 */
void *thread_routine(void *arg)
{
    printf("[OK ] Enter thread\n");
    fflush(stdout);   /**< Ensure the output is printed immediately */
    pthread_exit(NULL);   /**< Terminate the thread */
    return NULL;  /**< Return NULL, although it's not necessary after pthread_exit */
}

/**
 * @brief Main function that creates and manages threads.
 *
 * The main function creates a thread using `pthread_create()`, then
 * waits for the thread to finish using `pthread_join()`. Various messages
 * are printed to show the flow of the program.
 *
 * @param argc The number of arguments passed to the program (not used).
 * @param argv Array of arguments passed to the program (not used).
 * @return 0 if everything is successful, 1 if there are errors.
 */
int main(int argc, char** argv)
{
    printf("🟡 In main, before creating thread...\n");
    fflush(stdout);   /**< Ensure the output is printed immediately */

    pthread_t tid;
    if (pthread_create(&tid, NULL, thread_routine, NULL) != 0) {
        printf("❌ Failed to create thread\n");
        fflush(stdout);
        return 1;   /**< Return 1 if thread creation fails */
    }

    printf("🟢 Thread created. Joining...\n");
    fflush(stdout);  

    if (pthread_join(tid, NULL) != 0) {
        printf("❌ Failed to join thread 😞\n");
        fflush(stdout);
        return 1;   /**< Return 1 if joining the thread fails */
    }

    printf("✅ Exit main\n");
    fflush(stdout);   /**< Ensure the output is printed immediately */
    return 0;   /**< Return 0 if everything was successful */
}
