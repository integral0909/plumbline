# Plumbline build
#
# Targets:
#   make            build the plumbline executable
#   make test       build and run the unit test suites
#   make clean      remove build output
#
# Set VERBOSE=1 to see full TAP output from passing suites.

COBC      ?= cobc
BUILD     ?= build
COBFLAGS  ?= -free -Wall -fstatic-call -I copy
EXTRA_COBFLAGS ?=

ALL_FLAGS := $(COBFLAGS) $(EXTRA_COBFLAGS)

LIB_SRC   := $(wildcard src/lib/*.cob)
LIB_OBJ   := $(patsubst src/lib/%.cob,$(BUILD)/obj/%.o,$(LIB_SRC))
COPYBOOKS := $(wildcard copy/*.cpy)

BIN       := $(BUILD)/bin/plumbline

HARNESS_SRC := $(wildcard tests/harness/*.cob)
HARNESS_OBJ := $(patsubst tests/harness/%.cob,$(BUILD)/obj/harness/%.o,$(HARNESS_SRC))
TEST_SRC    := $(wildcard tests/unit/test-*.cob)
TEST_BIN    := $(patsubst tests/unit/%.cob,$(BUILD)/tests/%,$(TEST_SRC))

.PHONY: all clean test tests
.SECONDARY: $(HARNESS_OBJ) $(LIB_OBJ)

all: $(BIN)

tests: $(TEST_BIN)

test: $(TEST_BIN)
	tools/run-tests.sh $(TEST_BIN)

$(BUILD)/obj/%.o: src/lib/%.cob $(COPYBOOKS) | $(BUILD)/obj
	$(COBC) -c $(ALL_FLAGS) -o $@ $<

$(BIN): src/cli/plumbline.cob $(LIB_OBJ) $(COPYBOOKS) | $(BUILD)/bin
	$(COBC) -x $(ALL_FLAGS) -o $@ $< $(LIB_OBJ)

$(BUILD)/obj/harness/%.o: tests/harness/%.cob tests/harness/plbtstate.cpy | $(BUILD)/obj/harness
	$(COBC) -c $(ALL_FLAGS) -I tests/harness -o $@ $<

$(BUILD)/tests/%: tests/unit/%.cob $(LIB_OBJ) $(HARNESS_OBJ) $(COPYBOOKS) | $(BUILD)/tests
	$(COBC) -x $(ALL_FLAGS) -I tests/harness -o $@ $< $(LIB_OBJ) $(HARNESS_OBJ)

$(BUILD)/obj $(BUILD)/bin $(BUILD)/obj/harness $(BUILD)/tests:
	mkdir -p $@

clean:
	rm -rf $(BUILD)
