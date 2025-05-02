WASI_SDK_PATH = /opt/wasi-sdk
WASIX_SYSROOT = $(WASI_SDK_PATH)/wasix-sysroot
CC            = $(WASI_SDK_PATH)/bin/clang --target=wasm32-wasi
LD = $(WASI_SDK_PATH)/bin/wasm-ld 

CFLAGS        = \
  --sysroot=$(WASIX_SYSROOT) \
  -O0 \
-matomics \
         -mbulk-memory \
         -mmutable-globals \
         -pthread \
         -mthread-model posix \
         -ftls-model=local-exec \
         -fno-trapping-math \
         -D_WASI_EMULATED_MMAN \
         -D_WASI_EMULATED_SIGNAL \
		 -D_WASI_EMULATED_PROCESS_CLOCKS \
         -Wall \
         -Wextra \
         -Werror \
         -Wno-incompatible-pointer-types \
         -Wno-int-conversion\
         -Wno-null-pointer-arithmetic \
         -Wno-unused-parameter \
         -Wno-sign-compare \
         -Wno-unused-variable \
         -Wno-format \
         -Wno-format-extra-args \
         -Wno-unused-function \
         -Wno-deprecated-non-prototype \
         -Wno-ignored-attributes \
         -Wno-missing-braces \
         -Wno-ignored-pragmas \
         -Wno-implicit-function-declaration \
         -Wno-implicit-int \
         -Wno-unused-but-set-variable \
         -Wno-unknown-warning-option \
         -Wno-parentheses \
         -Wno-shift-op-parentheses \
         -Wno-bitwise-op-parentheses \
         -Wno-logical-op-parentheses \
         -Wno-string-plus-int \
         -Wno-dangling-else \
         -Wno-unknown-pragmas \
          -I$(WASIX_SYSROOT)/include \
         -include wasi_override.h \

LDFLAGS       = \
  -L$(WASIX_SYSROOT)/lib \
  -lc -lm -lpthread -ldl -lrt -pthread \


OUTDIR        = wasibench
SRCDIR        = byte-unixbench/UnixBench/src

TARGETS = \
  $(OUTDIR)/arithoh.wasm \
  $(OUTDIR)/register.wasm \
  $(OUTDIR)/short.wasm \
  $(OUTDIR)/int.wasm \
  $(OUTDIR)/thread_test.wasm 
  # $(OUTDIR)/dhry2.wasm \
  # $(OUTDIR)/whetstone-double.wasm \
  # $(OUTDIR)/pipe.wasm \
  # $(OUTDIR)/execl.wasm \
  # $(OUTDIR)/spawn.wasm \
  # $(OUTDIR)/hanoi.wasm 

.PHONY: all clean

all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)


$(OUTDIR)/thread_test.wasm: dummy/thread_test.c 
	$(CC) $(CFLAGS) -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)

$(OUTDIR)/arithoh.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Darithoh -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)

$(OUTDIR)/register.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Ddatum='register int' -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)

$(OUTDIR)/short.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Ddatum=short -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)

$(OUTDIR)/int.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Ddatum=int -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)

$(OUTDIR)/long.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Ddatum=long -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)

$(OUTDIR)/float.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Ddatum=float -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)

$(OUTDIR)/double.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Ddatum=double -fuse-ld=$(LD)  -o $@ $^ $(LDFLAGS)




$(OUTDIR)/whetstone-double.wasm: $(SRCDIR)/whets.c
	$(CC) $(CFLAGS) -DDP -DGTODay -DUNIXBENCH -lm \
	  -o $@ $(SRCDIR)/whets.c -fuse-ld=$(LD) 

$(OUTDIR)/dhry2.wasm: $(SRCDIR)/dhry_1.c $(SRCDIR)/dhry_2.c 
	$(CC) $(CFLAGS) -DHZ=100 -o $@ \
	  $(SRCDIR)/dhry_1.c  $(SRCDIR)/dhry_2.c -fuse-ld=$(LD)  $(LDFLAGS)

# pipe
$(OUTDIR)/pipe.wasm: $(SRCDIR)/pipe.c  
	$(CC) $(CFLAGS)  -fuse-ld=$(LD)  -o $@ $^
# execl (needs big.c)
$(OUTDIR)/execl.wasm: $(SRCDIR)/execl.c 
	$(CC) $(CFLAGS)  -fuse-ld=$(LD)  -o $@ $^
# spawn
$(OUTDIR)/spawn.wasm: $(SRCDIR)/spawn.c  
	$(CC) $(CFLAGS)  -fuse-ld=$(LD)  -o $@ $^
# hanoi
$(OUTDIR)/hanoi.wasm: $(SRCDIR)/hanoi.c  
	$(CC) -g $(CFLAGS)  -fuse-ld=$(LD)  -o $@ $^
# fstime (no timeit.c)
$(OUTDIR)/fstime.wasm: $(SRCDIR)/fstime.c
	$(CC) $(CFLAGS) -o $@ $<
# syscall
$(OUTDIR)/syscall.wasm: $(SRCDIR)/syscall.c  
	$(CC) $(CFLAGS)  -fuse-ld=$(LD)  -o $@ $^
# context1
$(OUTDIR)/context1.wasm: $(SRCDIR)/context1.c  
	$(CC) $(CFLAGS)  -fuse-ld=$(LD)  -o $@ $^
# looper
$(OUTDIR)/looper.wasm: $(SRCDIR)/looper.c  
	$(CC) $(CFLAGS)  -fuse-ld=$(LD)  -o $@ $^





clean:
	rm -f $(OUTDIR)/*.wasm
