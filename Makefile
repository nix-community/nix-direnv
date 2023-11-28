# {{{ setup

MAKEFLAGS += \
	--no-builtin-rules \
	--no-builtin-variables \
	--warn-undefined-variables

SHELL = bash
export SHELLOPTS=errexit:pipefail

define NIX_CONFIG ?=
experimental-features = nix-command flakes
log-lines = 0
endef
export NIX_CONFIG

NIX ?= nix

NIX_ARGS ?= -L

SYSTEM != printf %s $$(uname -m)-$$(uname -s | tr "[:upper:]" "[:lower:]")

# arguments passed to recipes
ARGS ?=

check = .\#checks.$(SYSTEM).$1

# }}}

# {{{ build

.PHONY: result
result:
	$(strip $(NIX) $(NIX_ARGS) build $(ARGS))

# }}}

# {{{ lint

.PHONY: lint
lint: override ARGS += --out-link lint $(call check,lint)
lint: result

# }}}

# {{{ test

# coverage report type, see https://coverage.readthedocs.io/en/7.3.2/cmd.html
COV_REPORT ?= term-missing:skip-covered

TEST_GCROOT ?= .test_gcroot
$(TEST_GCROOT):
	mkdir $@

# define a test with two targets, one as <test_name>, other as <test_name>-cov
define TEST

.PHONY: $1
$1: $(TEST_GCROOT)
	$(NIX) --version
	$$(strip $(NIX) $(NIX_ARGS) develop $(call check,$1) \
		--profile $(TEST_GCROOT)/.profile_$1 \
		--command pytest $$(ARGS))

.PHONY: $1-cov
$1-cov: override ARGS += --cov --cov-context=test $(addprefix --cov-report=,$(COV_REPORT))
$1-cov: $1

endef

# default test with system nix
$(eval $(call TEST,test))

# make an include for the full set of tests so we don't have to ask nix flake each time
TESTS_MK = .tests.mk
$(TESTS_MK): flake.nix Makefile
	printf "TESTS = %s" "$$($(NIX) flake show --json 2>/dev/null \
		| jq --raw-output ".checks.\"$(SYSTEM)\" | keys | .[]" \
		| grep test_ \
		| tr \\n " ")" > $@

include $(TESTS_MK)

ifdef TESTS

# define targets for all tests
$(foreach test,$(TESTS),$(eval $(call TEST,$(test))))

# this one runs them together (make -j)
.PHONY: tests
tests: $(TESTS)

# generate github test matrix, see .github/workflows/test.yml
GITHUB_OUTPUT ?= github
$(GITHUB_OUTPUT): $(TESTS_MK)
	printf "tests=%s" '["$(shell sed 's/ /","/g' \
		<<< "$(strip $(patsubst test_%,%,$(filter test_nix%,$(TESTS))))")"]' > $@

.PHONY: github-test-matrix
github-test-matrix: $(GITHUB_OUTPUT)

endif  # ifdef TESTS

# }}}
