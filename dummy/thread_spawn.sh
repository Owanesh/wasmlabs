#!/bin/bash

# Ensure the source file exists
SOURCE_FILE="thread_spawn.c"
OUTFILE="/tmp/thread_spawn.js"

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
    -o $OUTFILE

node $OUTFILE
