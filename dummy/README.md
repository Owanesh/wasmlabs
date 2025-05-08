# Thread Spawn with WASI and Emscripten

This project was created to explore and test the various emulations and adaptations of **WASI (WebAssembly System Interface)** and **Emscripten (emcc)** using a simple program that creates and manages threads in a WebAssembly environment.

The base code is a simple C program that creates a thread, runs it, and joins it, with the addition of **emojis** to make the execution flow more fun.

## Description

The example code does the following:

1. Creates a **thread** using the `pthread` library in C.
2. Prints messages to the terminal to signal the execution state.
3. Uses **WASI** (via Wasmer) and **Emscripten** to compile and run the code in a WebAssembly environment with thread support.

## Source Code

The C program is very simple and uses `pthread` to handle the threads. 


### Compile with Emscripten (emcc) and run with node

To compile the code to WebAssembly using **Emscripten** and execute, run the following command:

```bash
bash thread_spawn.sh
emcc: warning: -pthread + ALLOW_MEMORY_GROWTH may run non-wasm code slowly, see https://github.com/WebAssembly/design/issues/1271 [-Wpthreads-mem-growth]

[OK ] Enter thread 🧵👨‍💻
Exit 👋
```


## Known Issues

* **Threading and compatibility**: Some versions of Wasmer might not fully support threading in WebAssembly, causing errors like `Failed to create the instance`.
* **pthread emulation**: WebAssembly doesn’t natively support threads, so emulations are needed to test `pthread` behavior.

## Conclusion

This example demonstrates how to compile and run a simple program using **threading** in WebAssembly with **WASI** and **Emscripten**. It’s a good starting point to explore the emulation capabilities and current limits of these tools, especially regarding thread support.

