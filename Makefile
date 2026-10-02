# Plumbline build
#
# Targets:
#   make            build the plumbline executable
#   make test       build and run the unit test suites
#   make coverage   run the tests with statement tracing and report
#                   COBOL line coverage (LCOV in build/coverage/)
#   make golden-update  rewrite golden test expectations from current
#                   output (review the diff before committing)
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

.PHONY: all clean test tests coverage golden-update
.SECONDARY: $(HARNESS_OBJ) $(LIB_OBJ)

all: $(BIN)

tests: $(TEST_BIN)

# Golden suites: directory and the plumbline command it exercises.
GOLDEN_SUITES := lexer:dump+tokens pp:dump+expanded+-I+tests/golden/pp/copy parser:dump+ast symbols:dump+symbols flow:dump+flow rules:check+--fail-on+never refs:dump+refs

# The plumbline command the tests run; make coverage substitutes a
# wrapper that collects traces.
RUN_BIN ?= $(BIN)

test: $(TEST_BIN) $(BIN)
	tools/run-tests.sh $(TEST_BIN)
	tests/cli/test-cli.sh $(RUN_BIN) > $(BUILD)/cli.tap || { cat $(BUILD)/cli.tap; exit 1; }
	@tail -n 1 $(BUILD)/cli.tap
	@for suite in $(GOLDEN_SUITES); do \
	    dir=$${suite%%:*}; cmd=$$(echo $${suite#*:} | tr + ' '); \
	    tests/golden/run-golden.sh $(RUN_BIN) tests/golden/$$dir $$cmd \
	        > $(BUILD)/golden-$$dir.tap || { cat $(BUILD)/golden-$$dir.tap; exit 1; }; \
	    tail -n 1 $(BUILD)/golden-$$dir.tap; \
	done
	tools/selfcheck.sh $(RUN_BIN)
	python3 -m unittest discover -s tests/tools -p 'test_*.py' -q

# Rewrite golden expectations from current output (review the diff!).
golden-update: $(BIN)
	@for suite in $(GOLDEN_SUITES); do \
	    dir=$${suite%%:*}; cmd=$$(echo $${suite#*:} | tr + ' '); \
	    GOLDEN_UPDATE=1 tests/golden/run-golden.sh $(BIN) tests/golden/$$dir $$cmd; \
	done

$(BUILD)/obj/%.o: src/lib/%.cob $(COPYBOOKS) | $(BUILD)/obj
	$(COBC) -c $(ALL_FLAGS) -o $@ $<

$(BIN): src/cli/plumbline.cob $(LIB_OBJ) $(COPYBOOKS) | $(BUILD)/bin
	$(COBC) -x $(ALL_FLAGS) -o $@ $< $(LIB_OBJ)

$(BUILD)/obj/harness/%.o: tests/harness/%.cob tests/harness/plbtstate.cpy | $(BUILD)/obj/harness
	$(COBC) -c $(ALL_FLAGS) -I tests/harness -o $@ $<

$(BUILD)/tests/%: tests/unit/%.cob $(LIB_OBJ) $(HARNESS_OBJ) $(COPYBOOKS) | $(BUILD)/tests
	$(COBC) -x $(ALL_FLAGS) -I tests/harness -o $@ $< $(LIB_OBJ) $(HARNESS_OBJ)

# Coverage: rebuild everything with statement tracing in a separate tree,
# run every test program through tools/cov-run.sh, which folds each
# process's trace into build/coverage/counts and deletes it, then map the
# counted lines back onto the executable lines found in the generated C.
COV_BUILD     := $(BUILD)/cov
COV_DIR       := $(BUILD)/coverage
COV_MIN       ?= 0
PRODUCT_SRC   := $(LIB_SRC) src/cli/plumbline.cob

coverage:
	rm -rf $(COV_DIR) && mkdir -p $(COV_DIR)/map
	$(MAKE) BUILD=$(COV_BUILD) EXTRA_COBFLAGS="-ftraceall" tests all
	for src in $(PRODUCT_SRC); do \
	    $(COBC) -C $(ALL_FLAGS) -ftraceall \
	        -o $(COV_DIR)/map/$$(basename $$src .cob).c $$src || exit 1; \
	done
	PLB_COV_DIR='$(CURDIR)/$(COV_DIR)' PLB_COV_BIN='$(CURDIR)/$(COV_BUILD)/bin/plumbline' \
	TEST_RUNNER='$(CURDIR)/tools/cov-run.sh' \
	    $(MAKE) BUILD=$(COV_BUILD) EXTRA_COBFLAGS="-ftraceall" \
	        RUN_BIN='$(CURDIR)/tools/cov-plumbline.sh' test
	tools/cobcov.py --include src/ --include copy/ \
	    --map $(COV_DIR)/map --counts $(COV_DIR)/counts \
	    --lcov $(COV_DIR)/lcov.info --fail-under $(COV_MIN)

$(BUILD)/obj $(BUILD)/bin $(BUILD)/obj/harness $(BUILD)/tests:
	mkdir -p $@

clean:
	rm -rf $(BUILD)
