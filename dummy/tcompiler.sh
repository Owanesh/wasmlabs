#!/bin/bash

# Check if input file is provided as argument
if [ -z "$1" ]; then
    echo "Usage: $0 <source_file.c> 📝"
    exit 1
fi

# Set the source file from the argument
SOURCE_FILE="$1"

# Ensure the source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Source file $SOURCE_FILE does not exist! ❌"
    exit 1
fi

# Get the filename without extension for output naming
BASE_NAME=$(basename "$SOURCE_FILE" .c)

# Compile with emcc
echo "----------------------"

echo "Compiling with emcc... 🔨"
emcc "$SOURCE_FILE" \
    -Wno-unused-command-line-argument -Wno-format \
    -Wl,--shared-memory -pthread \
    -Wno-deprecated-non-prototype \
    -O2 \
    -s ASSERTIONS=0 \
    -s EXIT_RUNTIME=1 \
    -s USE_PTHREADS=1 \
    -s PROXY_TO_PTHREAD=1 \
    -s PTHREAD_POOL_SIZE=4 \
    -s WASM_ASYNC_COMPILATION=1 \
    -s ENVIRONMENT=node \
    -s ALLOW_MEMORY_GROWTH=0 \
    -s TOTAL_MEMORY=256MB \
    -s STACK_SIZE=5242880 \
    -o "/tmp/${BASE_NAME}__emcc.js"

echo "Running emcc compiled code... 🚀"
echo "----------------------"

node "/tmp/${BASE_NAME}__emcc.js" 1

# Compile with wasm32-wasi-threads-clang
echo "----------------------"
echo "Compiling with wasm32-wasi-threads-clang... 🔨"
echo "📦 Target: /tmp/${BASE_NAME}__wasix.wasm"
echo "⏳ Please wait, compiling..."

/opt/wasi-sdk/bin/wasm32-wasi-threads-clang "$SOURCE_FILE" \
  -o "/tmp/${BASE_NAME}__wasix.wasm" \
  --target=wasm32-wasi  \
    -Wno-deprecated-non-prototype \
  --sysroot=/opt/wasi-sdk/wasix/sysroot \
  -pthread -D_WASI_EMULATED_PTHREAD \
  -Wl,--export-all,--shared-memory,--max-memory=134217728,--initial-memory=131072


echo "Running wasm32-wasi-threads-clang compiled code... 🏃‍♂️"
echo "----------------------"

wasmer run --enable-threads "/tmp/${BASE_NAME}__wasix.wasm" 1 \
  --env WASIX_PTHREAD_POOL_SIZE=4 \
  --env WASIX_PTHREAD_STACK_SIZE=5242880 \
  --env WASIX_PTHREAD_MAX_MEMORY=134217728 \
  --env WASIX_PTHREAD_MAX_STACK_SIZE=5242880
echo "----------------------"
echo "✅ Finished executing the script!"
echo "🗑️ Cleaning up temporary files..."
rm -f "/tmp/${BASE_NAME}__emcc.js" "/tmp/${BASE_NAME}__wasix.wasm"
echo "🗑️ Temporary files cleaned up!"