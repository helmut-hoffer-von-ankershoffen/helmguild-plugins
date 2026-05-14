# Helmguild plugins marketplace — local test + validate harness.
# Mirrors the CI workflow in .github/workflows/validate.yml so a
# `make check` locally catches every failure CI would catch.

SHELL := /usr/bin/env bash

.PHONY: check validate test plugin-validate help

help:
	@printf 'Targets:\n'
	@printf '  make check            — run every gate (validate + test + plugin-validate)\n'
	@printf '  make validate         — marketplace schema validator\n'
	@printf '  make test             — every plugin tests/ — discovers .sh + .mjs\n'
	@printf '  make plugin-validate  — `claude plugin validate` on every plugin\n'

check: validate test plugin-validate
	@echo "all green"

validate:
	@python3 .github/scripts/validate.py

test:
	@set -euo pipefail; \
	fail=0; \
	shopt -s nullglob; \
	for plugin in plugins/*/; do \
	  tests_dir="$$plugin/tests"; \
	  [[ -d "$$tests_dir" ]] || continue; \
	  for t in "$$tests_dir"/*.mjs "$$tests_dir"/*.sh; do \
	    [[ -f "$$t" ]] || continue; \
	    name="$$(basename "$$plugin")/$$(basename "$$t")"; \
	    case "$$t" in \
	      *.mjs) if node --test "$$t" >/dev/null 2>&1; then echo "✓ $$name"; else echo "✗ $$name"; node --test "$$t" >&2 || true; fail=1; fi ;; \
	      *.sh)  if bash "$$t" >/dev/null 2>&1; then echo "✓ $$name"; else echo "✗ $$name"; bash "$$t" >&2 || true; fail=1; fi ;; \
	    esac; \
	  done; \
	done; \
	exit $$fail

plugin-validate:
	@command -v claude >/dev/null 2>&1 || { echo "claude CLI not installed; skipping plugin-validate"; exit 0; }
	@set -euo pipefail; \
	fail=0; \
	shopt -s nullglob; \
	for plugin in plugins/*/; do \
	  if claude plugin validate "$$plugin" >/dev/null 2>&1; then \
	    echo "✓ $$(basename "$$plugin")"; \
	  else \
	    echo "✗ $$(basename "$$plugin")"; \
	    claude plugin validate "$$plugin" >&2 || true; \
	    fail=1; \
	  fi; \
	done; \
	exit $$fail
