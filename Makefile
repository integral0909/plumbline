# Plumbline build
#
# Targets:
#   make            build the plumbline executable
#   make test       build and run the unit test suites
#   make coverage   run the tests with statement tracing and report
#                   COBOL line coverage (LCOV in build/coverage/)
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

.PHONY: all clean test tests coverage
.SECONDARY: $(HARNESS_OBJ) $(LIB_OBJ)

all: $(BIN)

tests: $(TEST_BIN)

test: $(TEST_BIN) $(BIN)
	tools/run-tests.sh $(TEST_BIN)
	tests/cli/test-cli.sh $(BIN) > $(BUILD)/cli.tap || { cat $(BUILD)/cli.tap; exit 1; }
	@tail -n 1 $(BUILD)/cli.tap
	python3 -m unittest discover -s tests/tools -p 'test_*.py' -q

$(BUILD)/obj/%.o: src/lib/%.cob $(COPYBOOKS) | $(BUILD)/obj
	$(COBC) -c $(ALL_FLAGS) -o $@ $<

$(BIN): src/cli/plumbline.cob $(LIB_OBJ) $(COPYBOOKS) | $(BUILD)/bin
	$(COBC) -x $(ALL_FLAGS) -o $@ $< $(LIB_OBJ)

$(BUILD)/obj/harness/%.o: tests/harness/%.cob tests/harness/plbtstate.cpy | $(BUILD)/obj/harness
	$(COBC) -c $(ALL_FLAGS) -I tests/harness -o $@ $<

$(BUILD)/tests/%: tests/unit/%.cob $(LIB_OBJ) $(HARNESS_OBJ) $(COPYBOOKS) | $(BUILD)/tests
	$(COBC) -x $(ALL_FLAGS) -I tests/harness -o $@ $< $(LIB_OBJ) $(HARNESS_OBJ)

# Coverage: rebuild everything with statement tracing in a separate tree,
# run the tests with one trace file per process, then map traced lines
# back onto the executable lines found in the generated C.
COV_BUILD     := $(BUILD)/cov
COV_DIR       := $(BUILD)/coverage
COV_MIN       ?= 0
PRODUCT_SRC   := $(LIB_SRC) src/cli/plumbline.cob

coverage:
	rm -rf $(COV_DIR) && mkdir -p $(COV_DIR)/map $(COV_DIR)/trace
	$(MAKE) BUILD=$(COV_BUILD) EXTRA_COBFLAGS="-ftraceall" tests all
	for src in $(PRODUCT_SRC); do \
	    $(COBC) -C $(ALL_FLAGS) -ftraceall \
	        -o $(COV_DIR)/map/$$(basename $$src .cob).c $$src || exit 1; \
	done
	COB_SET_TRACE=Y COB_TRACE_FORMAT='%F|%L' \
	COB_TRACE_FILE='$(CURDIR)/$(COV_DIR)/trace/t_$$$$.trace' \
	    sh -c 'tools/run-tests.sh $(patsubst $(BUILD)/%,$(COV_BUILD)/%,$(TEST_BIN)) && \
	           tests/cli/test-cli.sh $(COV_BUILD)/bin/plumbline > /dev/null'
	tools/cobcov.py --include src/ --include copy/ \
	    --map $(COV_DIR)/map --trace $(COV_DIR)/trace \
	    --lcov $(COV_DIR)/lcov.info --fail-under $(COV_MIN)

$(BUILD)/obj $(BUILD)/bin $(BUILD)/obj/harness $(BUILD)/tests:
	mkdir -p $@

clean:
	rm -rf $(BUILD)
