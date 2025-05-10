# Configuration
WASIX_SYSROOT = /path/to/wasix-sysroot
CC            = emcc
WASI_OVERRIDE = wasitime.h

# Common flags
COMMON_WARNINGS = \
    -Wno-unused-command-line-argument -Wno-format \
    -Wl,--shared-memory -pthread \
    -Wno-deprecated-non-prototype \

CFLAGS = \
    -include $(WASI_OVERRIDE) \
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
  $(COMMON_WARNINGS)

LDFLAGS =

# Directories
OUTDIR = wasibench
SRCDIR = byte-unixbench/UnixBench/src

# Targets
TARGETS = \
  $(OUTDIR)/arithoh.js \
  $(OUTDIR)/register.js \
  $(OUTDIR)/short.js \
  $(OUTDIR)/int.js \
  $(OUTDIR)/long.js \
  $(OUTDIR)/float.js \
  $(OUTDIR)/double.js \
  $(OUTDIR)/pipe.js \
  $(OUTDIR)/execl.js \
  $(OUTDIR)/spawn.js \
  $(OUTDIR)/hanoi.js \
  $(OUTDIR)/fstime.js \
  $(OUTDIR)/syscall.js \
  $(OUTDIR)/looper.js \
  $(OUTDIR)/whetstone-double.js
#   $(OUTDIR)/context1.js 

.PHONY: all clean

all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $@

# === arithoh and variants ===
$(OUTDIR)/arithoh.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Darithoh -o $@ $^

$(OUTDIR)/register.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum='register int' -o $@ $^

$(OUTDIR)/short.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=short -o $@ $^

$(OUTDIR)/int.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=int -o $@ $^

$(OUTDIR)/long.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=long -o $@ $^

$(OUTDIR)/float.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=float -o $@ $^

$(OUTDIR)/double.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS) -Ddatum=double -o $@ $^

# === individual tests ===
$(OUTDIR)/pipe.js: $(SRCDIR)/pipe.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/execl.js: $(SRCDIR)/execl.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/spawn.js: $(SRCDIR)/spawn.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/hanoi.js: $(SRCDIR)/hanoi.c
	$(CC) $(CFLAGS) -g -o $@ $^

$(OUTDIR)/fstime.js: $(SRCDIR)/fstime.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/syscall.js: $(SRCDIR)/syscall.c
	$(CC) $(CFLAGS) -o $@ $^

# $(OUTDIR)/context1.js: $(SRCDIR)/context1.c
# 	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/looper.js: $(SRCDIR)/looper.c
	$(CC) $(CFLAGS) -o $@ $^

# === whetstone ===
$(OUTDIR)/whetstone-double.js: $(SRCDIR)/whets.c
	$(CC) $(CFLAGS) -DDP -DGTODay -DUNIXBENCH -o $@ $<

# === Clean ===
clean:
	rm -rf $(OUTDIR)/*.js
	rm -rf $(OUTDIR)/*.wasm

