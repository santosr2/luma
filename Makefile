.PHONY: help test lint format clean install dev docs coverage release

help:
	@echo "Luma - Development Commands"
	@echo ""
	@echo "Available targets:"
	@echo "  make install    - Install dependencies"
	@echo "  make dev        - Setup development environment"
	@echo "  make test       - Run test suite"
	@echo "  make lint       - Run linter"
	@echo "  make format     - Format code"
	@echo "  make coverage   - Generate coverage report"
	@echo "  make docs       - Generate documentation"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make release    - Create release"

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
	luacheck luma/ cli/ spec/ \
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

ci: lint test-coverage
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
	@echo "Running benchmarks..."
	@lua -e "local luma = require('luma'); \
		local start = os.clock(); \
		for i=1,1000 do \
			luma.render('Hello {{ name }}!', {name='World'}); \
		end; \
		print(string.format('1000 renders: %.3fs', os.clock() - start))"

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

