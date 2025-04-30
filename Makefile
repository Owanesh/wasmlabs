WASI_SDK_PATH = /opt/wasi-sdk
CC            = $(WASI_SDK_PATH)/bin/clang --target=wasm32-wasi
CFLAGS        = \
  --sysroot=$(WASI_SDK_PATH)/share/wasi-sysroot \
  -O3 -Wall -Wextra -Wno-unused \
  -D_WASI_EMULATED_SIGNAL \
  -D_WASI_EMULATED_PROCESS_CLOCKS \
  -Wno-deprecated-non-prototype -Wno-main-return-type -Wno-implicit-function-declaration \
  -Wno-unused-function -Wno-unused-variable -Wno-unused-parameter \
  -include wasi_override.h

LDFLAGS       = \
  -lwasi-emulated-signal\
  -lwasi-emulated-process-clocks

OUTDIR        = wasibench
SRCDIR        = byte-unixbench/UnixBench/src

TARGETS = \
  $(OUTDIR)/arithoh.wasm \
  $(OUTDIR)/dhry2.wasm \
  $(OUTDIR)/whetstone-double.wasm

.PHONY: all clean

all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)


$(OUTDIR)/arithoh.wasm: $(SRCDIR)/arith.c 
	$(CC) $(CFLAGS) -Darithoh -o $@ \
	  $(SRCDIR)/arith.c  $(LDFLAGS)

$(OUTDIR)/whetstone-double.wasm: $(SRCDIR)/whets.c
	$(CC) $(CFLAGS) -DDP -DGTODay -DUNIXBENCH -lm \
	  -o $@ $(SRCDIR)/whets.c

$(OUTDIR)/dhry2.wasm: $(SRCDIR)/dhry_1.c $(SRCDIR)/dhry_2.c 
	$(CC) $(CFLAGS) -DHZ=100 -o $@ \
	  $(SRCDIR)/dhry_1.c  $(SRCDIR)/dhry_2.c $(LDFLAGS)

clean:
	rm -f $(OUTDIR)/*.wasm
