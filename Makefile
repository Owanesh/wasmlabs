# Configuration
CC            = emcc
WASI_OVERRIDE = src_patch/wasitime.h

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
  $(OUTDIR)/execl.js \
  $(OUTDIR)/spawn.js \
  $(OUTDIR)/hanoi.js \
  $(OUTDIR)/fstime.js \
  $(OUTDIR)/syscall.js \
  $(OUTDIR)/looper.js \
  $(OUTDIR)/whetstone-double.js
#   $(OUTDIR)/context1.js \
  # $(PROGDIR)/dhry2.js \
  # $(PROGDIR)/dhry2reg.js

.PHONY: all clean run

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


$(OUTDIR)/hanoi.js: $(SRCDIR)/hanoi.c
	$(CC) $(CFLAGS) -g -o $@ $^

$(OUTDIR)/fstime.js: $(SRCDIR)/fstime.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/syscall.js: $(SRCDIR)/syscall.c
	$(CC) $(CFLAGS) -o $@ $^

# $(OUTDIR)/context1.js: $(SRCDIR)/context1.c
# 	$(CC) $(CFLAGS) -o $@ $^

# === PATCHED ===
$(OUTDIR)/looper.js: $(SRCPATCHDIR)/looper.c
	$(CC) $(CFLAGS) -o $@ $^

$(OUTDIR)/spawn.js: $(SRCPATCHDIR)/spawn.c
	$(CC) $(CFLAGS) -o $@ $^

# === whetstone ===
$(OUTDIR)/whetstone-double.js: $(SRCDIR)/whets.c
	$(CC) $(CFLAGS) -DDP -DGTODay -DUNIXBENCH -o $@ $<


# $(PROGDIR)/dhry2.js: CFLAGS += -DHZ=${HZ}
# $(PROGDIR)/dhry2.js: $(SRCDIR)/dhry_1.c $(SRCDIR)/dhry_2.c \
#                   $(SRCDIR)/dhry.h $(SRCDIR)/timeit.c
# 	$(CC) -o $@ ${CFLAGS} $(SRCDIR)/dhry_1.c $(SRCDIR)/dhry_2.c

# $(PROGDIR)/dhry2reg.js: CFLAGS += -DHZ=${HZ} -DREG=register
# $(PROGDIR)/dhry2reg.js: $(SRCDIR)/dhry_1.c $(SRCDIR)/dhry_2.c \
#                      $(SRCDIR)/dhry.h $(SRCDIR)/timeit.c
# 	$(CC) -o $@ ${CFLAGS} $(SRCDIR)/dhry_1.c $(SRCDIR)/dhry_2.c






# === Clean ===
clean:
	rm -rf $(OUTDIR)/*.js
	rm -rf $(OUTDIR)/*.wasm

run:
	bash ./Run
