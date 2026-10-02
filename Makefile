# Plumbline build
#
# Targets:
#   make            build the plumbline executable
#   make test       build and run the unit test suites
#   make clean      remove build output

COBC      ?= cobc
BUILD     ?= build
COBFLAGS  ?= -free -Wall -fstatic-call -I copy
EXTRA_COBFLAGS ?=

ALL_FLAGS := $(COBFLAGS) $(EXTRA_COBFLAGS)

LIB_SRC   := $(wildcard src/lib/*.cob)
LIB_OBJ   := $(patsubst src/lib/%.cob,$(BUILD)/obj/%.o,$(LIB_SRC))
COPYBOOKS := $(wildcard copy/*.cpy)

BIN       := $(BUILD)/bin/plumbline

.PHONY: all clean

all: $(BIN)

$(BUILD)/obj/%.o: src/lib/%.cob $(COPYBOOKS) | $(BUILD)/obj
	$(COBC) -c $(ALL_FLAGS) -o $@ $<

$(BIN): src/cli/plumbline.cob $(LIB_OBJ) $(COPYBOOKS) | $(BUILD)/bin
	$(COBC) -x $(ALL_FLAGS) -o $@ $< $(LIB_OBJ)

$(BUILD)/obj $(BUILD)/bin:
	mkdir -p $@

clean:
	rm -rf $(BUILD)
