# Toolchain
WASI_SDK_PATH = /opt/wasi-sdk
CC            = $(WASI_SDK_PATH)/bin/wasm32-wasi-threads-clang
LD            = $(WASI_SDK_PATH)/bin/wasm-ld
AR            = $(WASI_SDK_PATH)/bin/llvm-ar
NM            = $(WASI_SDK_PATH)/bin/llvm-nm

# Flags
COMMON_WARNINGS = \
  -Wall -Wextra -Werror \
  -Wno-incompatible-pointer-types -Wno-int-conversion \
  -Wno-null-pointer-arithmetic -Wno-unused-parameter \
  -Wno-sign-compare -Wno-unused-variable -Wno-format \
  -Wno-format-extra-args -Wno-unused-function \
  -Wno-deprecated-non-prototype -Wno-ignored-attributes \
  -Wno-missing-braces -Wno-ignored-pragmas \
  -Wno-implicit-function-declaration -Wno-implicit-int \
  -Wno-unused-but-set-variable -Wno-unknown-warning-option \
  -Wno-parentheses -Wno-shift-op-parentheses \
  -Wno-bitwise-op-parentheses -Wno-logical-op-parentheses \
  -Wno-string-plus-int -Wno-dangling-else \
  -Wno-unknown-pragmas

CFLAGS = \
  -O0 -matomics -mbulk-memory -mmutable-globals -pthread \
  -ftls-model=local-exec -fno-trapping-math \
  -D_WASI_EMULATED_MMAN  \
  $(COMMON_WARNINGS) \
  -Wl,--shared-memory

LDFLAGS = -lc -lm -lpthread -ldl -lrt -pthread

# Directories
OUTDIR = wasibench
SRCDIR = byte-unixbench/UnixBench/src

# Explicit list of all targets
TARGETS = \
  $(OUTDIR)/arithoh.wasm \
  $(OUTDIR)/register.wasm \
  $(OUTDIR)/short.wasm \
  $(OUTDIR)/int.wasm \
  $(OUTDIR)/long.wasm \
  $(OUTDIR)/float.wasm \
  $(OUTDIR)/double.wasm \
  $(OUTDIR)/pipe.wasm \
  $(OUTDIR)/execl.wasm \
  $(OUTDIR)/spawn.wasm \
  $(OUTDIR)/hanoi.wasm \
  $(OUTDIR)/fstime.wasm \
  $(OUTDIR)/syscall.wasm \
  $(OUTDIR)/context1.wasm \
  $(OUTDIR)/looper.wasm \
  $(OUTDIR)/thread_test.wasm \
  $(OUTDIR)/whetstone-double.wasm

.PHONY: all clean emcc

all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $@

# === arithoh ===
$(OUTDIR)/arithoh.wasm: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Darithoh -o $@ $^ $(LDFLAGS)

# === datum variants ===
$(OUTDIR)/register.wasm: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum='register int' -o $@ $^ $(LDFLAGS)

$(OUTDIR)/short.wasm: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=short -o $@ $^ $(LDFLAGS)

$(OUTDIR)/int.wasm: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=int -o $@ $^ $(LDFLAGS)

$(OUTDIR)/long.wasm: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=long -o $@ $^ $(LDFLAGS)

$(OUTDIR)/float.wasm: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=float -o $@ $^ $(LDFLAGS)

$(OUTDIR)/double.wasm: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=double -o $@ $^ $(LDFLAGS)

# === simple one-to-one ===
$(OUTDIR)/pipe.wasm: $(SRCDIR)/pipe.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/execl.wasm: $(SRCDIR)/execl.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/spawn.wasm: $(SRCDIR)/spawn.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/hanoi.wasm: $(SRCDIR)/hanoi.c
	$(CC) -g $(CFLAGS) -o $@ $^

$(OUTDIR)/fstime.wasm: $(SRCDIR)/fstime.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/syscall.wasm: $(SRCDIR)/syscall.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/context1.wasm: $(SRCDIR)/context1.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/looper.wasm: $(SRCDIR)/looper.c
	$(CC) $(CFLAGS) -o $@ $^

# === thread_test ===
$(OUTDIR)/thread_test.wasm: dummy/thread_test.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# === whetstone ===
$(OUTDIR)/whetstone-double.wasm: $(SRCDIR)/whets.c
	$(CC) $(CFLAGS) -DDP -DGTODay -DUNIXBENCH -o $@ $< $(LDFLAGS)

# === emcc version ===
emcc:
	mkdir -p $(OUTDIR)

	emcc $(SRCDIR)/arith.c \
		$(COMMON_WARNINGS) -Wno-unused-command-line-argument \
		-Wl,--shared-memory -pthread -Darithoh \
		-Wno-threads-mem-growth \
		-s EXIT_RUNTIME=1 \
		-s ASSERTIONS=1 \
		-s ENVIRONMENT=node \
		-s NO_EXIT_RUNTIME=0 \
		-s USE_PTHREADS=1 \
		-s PTHREAD_POOL_SIZE=4 \
		-s ASYNCIFY=1 \
		-s WASM_ASYNC_COMPILATION=0 \
		-s ALLOW_MEMORY_GROWTH=1 \
		-s EXPORT_NAME='createAppModule' \
		-o $(OUTDIR)/arith.js

clean:
	rm -f $(OUTDIR)/*.wasm
