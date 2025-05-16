# WasmLabs

> 🚧 *Work in Progress* 🚧

 This repository is dedicated to exploring **WebAssembly** (WASM) and **WASI** by running classic C benchmarks in the browser and server environments. 💥

---

## 🎯 Purpose

- 🚀 **Experiment** with compiling well-known C benchmarks to WASM using **WASI**.
- ⚖️ **Compare** native C performance against WebAssembly performance.
- 📊 **Measure** and analyze runtime differences, startup times, and throughput.


## 📦 What's Inside

- 🔄 `Makefile` – A minimal Makefile to build selected benchmarks (`arithoh`, `dhry2`, `whetstone-double`) for WASI.
- 🧩 `src/` – Source code patches and overrides (`wasitime.h`) to stub missing POSIX APIs in WASI.
- 📊 `results/` – Scripts and data for running and comparing results.


## 🚀 Getting Started

1. **Install WASI SDK** (e.g., at `/opt/wasi-sdk`). 🛠️
2. **Clone byte-unixbench** repo 
3. **Tune original bench suite**

    - **src/ime.c** : since webassembly doesn't provide support for Signal/Alarm we need to avoid that this file is considered during compilation for wasm target
    ```c 
    #if defined(__GNUC__) && !defined(__wasi__)&& !defined(__EMSCRIPTEN__) && !defined(__wasix__)
    #include <signal.h>
    #include <unistd.h>

    void wake_me(seconds, func) int seconds;
    void (*func)();
    {
        /* set up the signal handler */
        signal(SIGALRM, func);
        /* get the clock running */
        alarm(seconds);
    }

    #endif
    ```
    - **src/syscall.c**, swap at lines 82 and 97 `syscall(SYS_getpid);` with `getpid();`

    

3. **Build the benchmarks**:
    ```bash
    make all
    ```
4. **Run with a Node runtime**: adaptation of original Perl script
   ```bash
    ./Run 
   ```


 