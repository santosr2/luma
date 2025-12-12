.PHONY: help test lint format clean install dev docs coverage release benchmark examples python-test

help:
	@echo "Luma - Development Commands"
	@echo ""
	@echo "Available targets:"
	@echo "  make install      - Install dependencies"
	@echo "  make dev          - Setup development environment"
	@echo "  make test         - Run test suite"
	@echo "  make lint         - Run linter"
	@echo "  make format       - Format code"
	@echo "  make coverage     - Generate coverage report"
	@echo "  make benchmark    - Run performance benchmarks"
	@echo "  make examples     - Run and validate examples"
	@echo "  make python-test  - Test Python bindings"
	@echo "  make docs         - Generate documentation"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make ci           - Run all CI checks locally"
	@echo "  make release      - Create release"

install:
	@echo "Installing dependencies..."
	luarocks install --local busted
	luarocks install --local luacheck
	luarocks install --local luacov
	luarocks install --local luacov-coveralls
	@echo "✓ Dependencies installed"
	@echo ""
	@echo "Note: Make sure your PATH includes ~/.luarocks/bin"
	@echo "Add to your shell profile:"
	@echo "  eval \$$(luarocks path --bin)"

dev: install
	@echo "Setting up development environment..."
	pip3 install pre-commit || echo "pre-commit not installed"
	pre-commit install || echo "Skipping pre-commit hooks"
	@echo "✓ Development environment ready"

test:
	@echo "Running tests..."
	busted --verbose spec/

test-coverage:
	@echo "Running tests with coverage..."
	busted --coverage spec/
	luacov
	@echo "✓ Coverage report generated: luacov.report.out"

lint:
	@echo "Running Luacheck..."
	luacheck luma/ cli/ benchmarks/ spec/ \
		--std=lua51+busted \
		--globals=describe,it,before_each,after_each,setup,teardown \
		--max-line-length=120

lint-strict:
	@echo "Running Luacheck (strict mode)..."
	luacheck luma/ cli/ \
		--std=lua51 \
		--max-line-length=120 \
		--max-cyclomatic-complexity=15 \
		--no-unused-args

format:
	@echo "Formatting code with stylua..."
	@if command -v stylua >/dev/null 2>&1; then \
		stylua luma/ cli/ spec/; \
		echo "✓ Code formatted"; \
	else \
		echo "⚠ stylua not installed, skipping formatting"; \
	fi

docs:
	@echo "Generating documentation..."
	@if command -v ldoc >/dev/null 2>&1; then \
		ldoc -c .ldoc luma/; \
		echo "✓ Documentation generated in doc/"; \
	else \
		echo "⚠ ldoc not installed"; \
		echo "Install: luarocks install ldoc"; \
	fi

coverage: test-coverage
	@echo "Opening coverage report..."
	@if [ -f luacov.report.out ]; then \
		cat luacov.report.out | head -50; \
	fi

clean:
	@echo "Cleaning build artifacts..."
	rm -f luacov.*.out
	rm -rf doc/
	rm -rf .luarocks/
	rm -rf lua_modules/
	find . -name "*.rockspec" -not -path "./.git/*" -delete
	@echo "✓ Cleaned"

check: lint test
	@echo "✓ All checks passed"

ci: lint test-coverage benchmark examples
	@echo "Running full CI suite..."
	@echo "✓ CI checks complete"

install-tools:
	@echo "Installing development tools..."
	luarocks install busted
	luarocks install luacheck
	luarocks install luacov
	luarocks install ldoc
	pip3 install pre-commit codespell
	@echo "✓ Tools installed"

validate:
	@echo "Validating project structure..."
	@test -f README.md || (echo "✗ README.md missing" && exit 1)
	@test -f LICENSE || (echo "✗ LICENSE missing" && exit 1)
	@test -f CONTRIBUTING.md || (echo "✗ CONTRIBUTING.md missing" && exit 1)
	@test -f SECURITY.md || (echo "✗ SECURITY.md missing" && exit 1)
	@test -d spec/ || (echo "✗ spec/ directory missing" && exit 1)
	@test -d luma/ || (echo "✗ luma/ directory missing" && exit 1)
	@echo "✓ Project structure valid"

benchmark:
	@echo "Running performance benchmarks..."
	@luajit benchmarks/run.lua
	@echo ""
	@echo "Running memory profiling..."
	@luajit benchmarks/memory_profile.lua
	@echo ""
	@echo "✓ Benchmarks complete"

benchmark-jit:
	@echo "Running JIT profiling..."
	@luajit benchmarks/jit_profile.lua

benchmark-stress:
	@echo "Running stress tests..."
	@luajit benchmarks/stress_test.lua

examples:
	@echo "Validating and running examples..."
	@for file in examples/*.luma; do \
		echo "Validating: $$file"; \
		luajit -e "package.path = package.path .. ';./?.lua;./?/init.lua'; \
			local luma = require('luma'); \
			local f = io.open('$$file', 'r'); \
			local source = f:read('*a'); \
			f:close(); \
			luma.compile(source)" || exit 1; \
	done
	@echo ""
	@for script in examples/run_*.lua; do \
		echo "Running: $$script"; \
		luajit "$$script" > /dev/null || exit 1; \
	done
	@echo "✓ All examples valid"

python-test:
	@echo "Testing Python bindings..."
	@cd bindings/python && \
		if [ -d .venv ]; then \
			. .venv/bin/activate && python -m pytest tests/ -v; \
		else \
			echo "⚠ Python venv not found. Run: cd bindings/python && mise exec -- uv venv && mise exec -- uv pip install pytest lupa"; \
			exit 1; \
		fi

release: clean check
	@echo "Preparing release..."
	@echo "1. Ensure version is updated in luma/version.lua"
	@echo "2. Update CHANGELOG.md"
	@echo "3. Commit changes"
	@echo "4. Create git tag: git tag -a v1.x.x -m 'Release 1.x.x'"
	@echo "5. Push: git push origin main --tags"
	@echo ""
	@read -p "Continue with release? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "\nCreating release..."; \
	else \
		echo "\nRelease cancelled"; \
		exit 1; \
	fi

.DEFAULT_GOAL := help

