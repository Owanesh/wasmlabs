# WasmLabs

> 🚧 *Work in Progress* 🚧

 This repository is dedicated to exploring **WebAssembly** (WASM) and **WASI** by running classic C benchmarks in the browser and server environments. 💥

---

## 🎯 Purpose

- 🚀 **Experiment** with compiling well-known C benchmarks to WASM using **WASI**.
- ⚖️ **Compare** native C performance against WebAssembly performance.
- 📊 **Measure** and analyze runtime differences, startup times, and throughput.


## 📦 What's Inside

- 🔄 `MakefileWasm` – A minimal Makefile to build selected benchmarks (`arithoh`, `dhry2`, `whetstone-double`) for WASI.
- 🧩 `src/` – Source code patches and overrides (`wasi_override.h`) to stub missing POSIX APIs in WASI.
- 📊 `benchmarks/` *(coming soon)* – Scripts and data for running and comparing results.


## 🚀 Getting Started

1. **Install WASI SDK** (e.g., at `/opt/wasi-sdk`). 🛠️
2. **Clone byte-unixbench** repo

    ```c 
    // timeit.c
    #ifndef __wasm32__
    void wake_me(seconds, func)
        int seconds;
        void (*func)();
    {
        /* set up the signal handler */
        signal(SIGALRM, func);
        /* get the clock running */
        alarm(seconds);
    }
    #endif
    ```

3. **Build the benchmarks**:
    ```bash
    make all
    ```
4. **Run with a WASI runtime** (Wasmtime or Wasmer):
   ```bash
    ➜ wasmtime wasibench/whetstone-double.wasm 1


    Calibrate
        0.00 Seconds          1   Passes (x 100)
        0.00 Seconds          5   Passes (x 100)
        0.02 Seconds         25   Passes (x 100)
        0.11 Seconds        125   Passes (x 100)
        0.53 Seconds        625   Passes (x 100)
    Use 11687  passes (x 100)

        Double Precision C/C++ Whetstone Benchmark
    [...]

    COUNT|11620.709|0|MWIPS
    TIME|10.057
   ```
5. **Compare** against native builds:
   ```bash
   <path_of_unixbench>/pgms/whetstone-double 1
   ```

 