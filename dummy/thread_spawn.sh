#!/bin/bash

# Ensure the source file exists
SOURCE_FILE="thread_spawn.c"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Source file $SOURCE_FILE does not exist!"
    exit 1
fi

# Compile with emcc
emcc $SOURCE_FILE \
    -Wno-unused-command-line-argument -Wno-format\
    -Wl,--shared-memory -pthread -Darithoh \
    -O2 \
    -sASSERTIONS=0 \
    -sUSE_PTHREADS=1 \
    -sPTHREAD_POOL_SIZE=4 \
    -sASYNCIFY=1 \
    -sWASM_ASYNC_COMPILATION=1 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sTOTAL_MEMORY=256MB \
    -sSTACK_SIZE=5242880 \
    -o /tmp/thread_spawn__emcc.js


echo "Running emcc compiled code..."
node /tmp/thread_spawn__emcc.js

echo "Compiling with wasm32-wasi-threads-clang..."
/opt/wasi-sdk/bin/wasm32-wasi-threads-clang thread_spawn.c \
  -o /tmp/thread_spawn__wasix.wasm \
  --target=wasm32-wasi \
  --sysroot=/opt/wasi-sdk/wasix/sysroot \
  -pthread -D_WASI_EMULATED_PTHREAD \
  -Wno-implicit-function-declaration -Wformat \
  -Wl,--export-all,--shared-memory,--max-memory=134217728,--initial-memory=131072

echo "Running wasm32-wasi-threads-clang compiled code..."

 wasmer run --enable-threads /tmp/thread_spawn__wasix.wasm \
  --env WASIX_PTHREAD_POOL_SIZE=4 \
  --env WASIX_PTHREAD_STACK_SIZE=5242880 \
  --env WASIX_PTHREAD_MAX_MEMORY=134217728 \
  --env WASIX_PTHREAD_MAX_STACK_SIZE=5242880
