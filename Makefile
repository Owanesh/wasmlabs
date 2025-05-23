# Configuration
CC            = emcc
WASI_OVERRIDE = src_patch/wasitime.h

# Common flags
COMMON_WARNINGS = \
    -Wno-unused-command-line-argument -Wno-format \
    -Wl,--shared-memory -pthread \
    -Wno-deprecated-non-prototype \

CFLAGS = \
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

CFLAGS_TIMEIT = \
    -include $(WASI_OVERRIDE) \
  $(CFLAGS)



LDFLAGS =

# Directories
OUTDIR = wasibench
SRCDIR = byte-unixbench/UnixBench/src
SRCPATCHDIR = src_patch
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
  $(OUTDIR)/spawn.js \
  $(OUTDIR)/hanoi.js \
  $(OUTDIR)/fstime.js \
  $(OUTDIR)/syscall.js \
  $(OUTDIR)/looper.js \
  $(OUTDIR)/whetstone-double.js \
  $(OUTDIR)/context1.js 
# $(OUTDIR)/dhry2.js\
# $(OUTDIR)/dhry2reg.js
# $(OUTDIR)/execl.js \

.PHONY: all clean run

all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $@

# === arithoh and variants ===
$(OUTDIR)/arithoh.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS_TIMEIT) -Darithoh -o $@ $^

$(OUTDIR)/register.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS_TIMEIT) -Ddatum='register int' -o $@ $^

$(OUTDIR)/short.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS_TIMEIT) -Ddatum=short -o $@ $^

$(OUTDIR)/int.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS_TIMEIT) -Ddatum=int -o $@ $^

$(OUTDIR)/long.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS_TIMEIT) -Ddatum=long -o $@ $^

$(OUTDIR)/float.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS_TIMEIT) -Ddatum=float -o $@ $^

$(OUTDIR)/double.js: $(SRCDIR)/arith.c
	$(CC) $(CFLAGS_TIMEIT) -Ddatum=double -o $@ $^

# === individual tests ===
$(OUTDIR)/pipe.js: $(SRCDIR)/pipe.c
	$(CC) $(CFLAGS_TIMEIT) -o $@ $^

$(OUTDIR)/hanoi.js: $(SRCDIR)/hanoi.c
	$(CC) $(CFLAGS_TIMEIT) -g -o $@ $^

$(OUTDIR)/fstime.js: $(SRCDIR)/fstime.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/syscall.js: $(SRCDIR)/syscall.c
	$(CC) $(CFLAGS_TIMEIT) -o $@ $^

# === PATCHED ===
$(OUTDIR)/looper.js: $(SRCPATCHDIR)/looper.c
	$(CC) $(CFLAGS_TIMEIT) -o $@ $^

$(OUTDIR)/spawn.js: $(SRCPATCHDIR)/spawn.c
	$(CC) $(CFLAGS_TIMEIT) -o $@ $^

$(OUTDIR)/context1.js: $(SRCPATCHDIR)/context1.c
	$(CC) $(CFLAGS_TIMEIT) -o $@ $^

$(OUTDIR)/whetstone-double.js: $(SRCDIR)/whets.c
	$(CC) $(CFLAGS) -DDP -DGTODay -DUNIXBENCH -o $@ $<

#$(OUTDIR)/execl.js: $(SRCPATCHDIR)/execl.c
#	$(CC) $(CFLAGS) -o $@ $^

# === Dhrystone ===
# The Dhrystone test is originally divided in two files:
# dhry_1.c and dhry_2.c. The first file contains the main function
# and the second file contains the rest of the code. The two files
# are combined into one file (dhry_combined.c) to avoid the need
# to link two files together.
#
# $(OUTDIR)/dhry2.js: CFLAGS += -DHZ=$(HZ)
# $(OUTDIR)/dhry2.js: $(SRCPATCHDIR)/dhry_combined.c 
# 	$(CC) $(CFLAGS_TIMEIT) -o $@ $(SRCPATCHDIR)/dhry_combined.c
#  
# $(OUTDIR)/dhry2reg.js: CFLAGS += -DHZ=$(HZ) -DREG=register
# $(OUTDIR)/dhry2reg.js: $(SRCPATCHDIR)/dhry_combined.c 
# 	$(CC) $(CFLAGS) -o $@ $(SRCPATCHDIR)/dhry_combined.c


# === Clean ===
clean:
	rm -rf $(OUTDIR)/*.js
	rm -rf $(OUTDIR)/*.wasm

run:
	./Run
