# =============================================================================
# videopress-backend — Makefile
# =============================================================================
# Mỗi target là 1 bước trong dev workflow. Default `make` sẽ in danh sách target.
# =============================================================================

.DEFAULT_GOAL := help

LAMBDAS := authentication_lambda notification_lambda upload_lambda compression_lambda job_status_lambda
DIST_DIR := dist
PYTHON := python3.11

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

.PHONY: install
install: ## Cài dev deps (black, pylint, pytest, mypy, coverage)
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -e ".[dev]"

# -----------------------------------------------------------------------------
# Quality gates
# -----------------------------------------------------------------------------

.PHONY: lint
lint: ## Chạy pylint trên shared/ + tất cả lambda
	pylint shared/ $(foreach l,$(LAMBDAS),$(l)/app.py $(l)/handlers/ $(l)/services/)

.PHONY: format
format: ## Auto-format toàn bộ code với black (line-length 100)
	black .

.PHONY: format-check
format-check: ## Check format không sửa file (dùng trong CI)
	black --check .

.PHONY: typecheck
typecheck: ## Static type-check với mypy
	mypy shared/ $(foreach l,$(LAMBDAS),$(l)/app.py)

.PHONY: test
test: ## Chạy pytest + coverage HTML report
	pytest --cov=. --cov-report=html --cov-report=term --cov-fail-under=70

.PHONY: test-fast
test-fast: ## Chạy pytest không coverage (nhanh hơn, dev local)
	pytest -x -v

# -----------------------------------------------------------------------------
# Build & Package
# -----------------------------------------------------------------------------

.PHONY: package
package: clean ## Build zip cho tất cả lambda (copy shared/ + cài deps + zip)
	@echo "==> Building $(words $(LAMBDAS)) lambda packages..."
	@mkdir -p $(DIST_DIR)
	@for lambda in $(LAMBDAS); do \
		echo ""; \
		echo "  → Packaging $$lambda"; \
		rm -rf $(DIST_DIR)/$$lambda; \
		mkdir -p $(DIST_DIR)/$$lambda; \
		cp -r shared $(DIST_DIR)/$$lambda/; \
		cp -r $$lambda/* $(DIST_DIR)/$$lambda/; \
		if [ -f $$lambda/requirements.txt ]; then \
			$(PYTHON) -m pip install -q -r $$lambda/requirements.txt -t $(DIST_DIR)/$$lambda/ \
				--platform manylinux2014_x86_64 --only-binary=:all: --upgrade || \
			$(PYTHON) -m pip install -q -r $$lambda/requirements.txt -t $(DIST_DIR)/$$lambda/; \
		fi; \
		find $(DIST_DIR)/$$lambda -name "tests" -type d -exec rm -rf {} +  2>/dev/null || true; \
		find $(DIST_DIR)/$$lambda -name "__pycache__" -type d -exec rm -rf {} +  2>/dev/null || true; \
		(cd $(DIST_DIR)/$$lambda && zip -qr ../$$lambda.zip .); \
		echo "  ✓ $(DIST_DIR)/$$lambda.zip"; \
	done
	@echo ""
	@echo "==> Done. Artifacts in $(DIST_DIR)/"
	@ls -lh $(DIST_DIR)/*.zip

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

.PHONY: clean
clean: ## Xoá build artifacts, coverage, cache
	rm -rf $(DIST_DIR)/ build/ htmlcov/ .coverage coverage.xml
	rm -rf .pytest_cache/ .mypy_cache/ .ruff_cache/
	find . -name "*.zip" -not -path "./.git/*" -delete 2>/dev/null || true
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete 2>/dev/null || true

# -----------------------------------------------------------------------------
# Help (default target)
# -----------------------------------------------------------------------------

.PHONY: help
help: ## In danh sách target khả dụng
	@echo "videopress-backend — available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
