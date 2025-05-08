#include <stdio.h>
#include <pthread.h>  
#include <stdlib.h>
#include <unistd.h>  // For sleep()

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
 * @brief Simulates a callback after a wait period.
 *
 * This function will wait for a specified number of seconds and
 * then execute the provided callback function.
 *
 * @param seconds The number of seconds to wait before calling the function.
 * @param callback A pointer to the function to call after waiting.
 */
void wake_me(int seconds, void (*callback)(void))
{
    printf("⏳ Waiting for %d seconds...\n", seconds);
    fflush(stdout);
    sleep(seconds);  /**< Sleep for the specified number of seconds */
    
    callback();  /**< Call the provided callback function after the wait */
}

/**
 * @brief The callback function that will be executed after the wait.
 *
 * This function is called by `wake_me()` after the specified wait time.
 */
void callback()
{
    printf("✅ Callback called after the wait.\n");
    fflush(stdout);
}

/**
 * @brief Main function that creates and manages threads.
 *
 * The main function creates a thread using `pthread_create()`, then
 * waits for the thread to finish using `pthread_join()`. It also
 * uses `wake_me` to wait for a specified amount of time before calling
 * a callback function.
 *
 * @param argc The number of arguments passed to the program (not used).
 * @param argv Array of arguments passed to the program (not used).
 * @return 0 if everything is successful, 1 if there are errors.
 */
int main(int argc, char** argv)
{
    printf("🟡 In main, before creating thread...\n");
    fflush(stdout);   

    // Schedule a callback after 3 seconds
    wake_me(3, callback);  /**< Call wake_me to wait for 3 seconds, then call callback() */

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
    fflush(stdout);   /**< Ensure the output is printed immediately */
    return 0;   /**< Return 0 if everything was successful */
}
