# Zig NIF for :gale (QPACK / HTTP/3 frames / QUIC header parse).
#
# Requires Zig 0.14+ (tested 0.16) and Erlang/OTP headers.

ERTS_INCLUDE_DIR ?= $(shell erl -noshell -eval 'io:format("~s", [code:lib_dir(erts, include)]), halt().')

PRIV_DIR := $(MIX_APP_PATH)/priv
PRIV_SO  := $(PRIV_DIR)/gale_nif.so
SRC      := native/zig/gale.zig

ZIG_BUILD_ARGS := \
	build-lib \
	-O ReleaseFast \
	-dynamic \
	-fallow-shlib-undefined \
	-femit-bin=$(PRIV_SO) \
	-I $(ERTS_INCLUDE_DIR) \
	-Mroot=$(SRC)

all: $(PRIV_SO)

$(PRIV_SO): $(SRC)
	@mkdir -p $(PRIV_DIR)
	zig $(ZIG_BUILD_ARGS)

clean:
	rm -f $(PRIV_SO)

.PHONY: all clean
