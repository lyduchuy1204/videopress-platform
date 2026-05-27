# =============================================================================
# VideoPress Infrastructure — Makefile
# Shortcut cho các thao tác Terraform thường dùng.
# Quy ước: chạy từ ROOT của repo, KHÔNG cd vào envs.
# =============================================================================

SHELL := /bin/bash
TF    := terraform

# Mỗi env trỏ tới folder envs/<env>
UAT_DIR     := envs/uat
STAGING_DIR := envs/staging
PROD_DIR    := envs/prod
BOOTSTRAP_DIR := bootstrap

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------
.PHONY: help
help:
	@echo "VideoPress Infrastructure — make targets"
	@echo ""
	@echo "  Bootstrap (1 lần per AWS account):"
	@echo "    make bootstrap-nonprod    Init+apply bootstrap stack cho account non-prod"
	@echo "    make bootstrap-prod       Init+apply bootstrap stack cho account prod"
	@echo ""
	@echo "  Init backend + provider plugin:"
	@echo "    make init-uat | init-staging | init-prod"
	@echo ""
	@echo "  Plan (KHÔNG apply gì):"
	@echo "    make plan-uat | plan-staging | plan-prod"
	@echo ""
	@echo "  Apply (chỉ làm sau khi review plan):"
	@echo "    make apply-uat | apply-staging | apply-prod"
	@echo ""
	@echo "  Destroy (chỉ UAT + Staging — KHÔNG có destroy-prod):"
	@echo "    make destroy-uat | destroy-staging"
	@echo ""
	@echo "  Quality:"
	@echo "    make fmt        terraform fmt -recursive"
	@echo "    make validate   terraform validate cho tất cả env"
	@echo "    make lint       tflint --recursive"
	@echo "    make security   tfsec ."
	@echo ""
	@echo "  Cost:"
	@echo "    make infracost-uat | infracost-prod"

# -----------------------------------------------------------------------------
# Bootstrap (chạy 1 lần per AWS account)
# -----------------------------------------------------------------------------
.PHONY: bootstrap-nonprod bootstrap-prod
bootstrap-nonprod:
	@echo "[bootstrap] account = nonprod"
	$(TF) -chdir=$(BOOTSTRAP_DIR) init
	$(TF) -chdir=$(BOOTSTRAP_DIR) apply -var="account_alias=nonprod"

bootstrap-prod:
	@echo "[bootstrap] account = prod (CẨN THẬN — apply ở account prod)"
	$(TF) -chdir=$(BOOTSTRAP_DIR) init
	$(TF) -chdir=$(BOOTSTRAP_DIR) apply -var="account_alias=prod"

# -----------------------------------------------------------------------------
# Init
# -----------------------------------------------------------------------------
.PHONY: init-uat init-staging init-prod
init-uat:
	$(TF) -chdir=$(UAT_DIR) init

init-staging:
	$(TF) -chdir=$(STAGING_DIR) init

init-prod:
	$(TF) -chdir=$(PROD_DIR) init

# -----------------------------------------------------------------------------
# Plan
# -----------------------------------------------------------------------------
.PHONY: plan-uat plan-staging plan-prod
plan-uat:
	$(TF) -chdir=$(UAT_DIR) plan -out=tfplan.bin

plan-staging:
	$(TF) -chdir=$(STAGING_DIR) plan -out=tfplan.bin

plan-prod:
	$(TF) -chdir=$(PROD_DIR) plan -out=tfplan.bin

# -----------------------------------------------------------------------------
# Apply
# -----------------------------------------------------------------------------
.PHONY: apply-uat apply-staging apply-prod
apply-uat:
	$(TF) -chdir=$(UAT_DIR) apply tfplan.bin

apply-staging:
	$(TF) -chdir=$(STAGING_DIR) apply tfplan.bin

apply-prod:
	@echo "⚠️  Apply Prod — chắc chắn đã có DynamoDB backup + state archive?"
	$(TF) -chdir=$(PROD_DIR) apply tfplan.bin

# -----------------------------------------------------------------------------
# Destroy — CHỈ UAT + Staging. KHÔNG có destroy-prod để an toàn.
# -----------------------------------------------------------------------------
.PHONY: destroy-uat destroy-staging
destroy-uat:
	$(TF) -chdir=$(UAT_DIR) destroy

destroy-staging:
	$(TF) -chdir=$(STAGING_DIR) destroy

# Cố tình KHÔNG có target destroy-prod. Muốn xoá prod phải vào folder thủ công + 2 reviewer.

# -----------------------------------------------------------------------------
# Quality
# -----------------------------------------------------------------------------
.PHONY: fmt validate lint security
fmt:
	$(TF) fmt -recursive

validate:
	@for d in $(UAT_DIR) $(STAGING_DIR) $(PROD_DIR) $(BOOTSTRAP_DIR); do \
	  echo "[validate] $$d"; \
	  $(TF) -chdir=$$d init -backend=false -upgrade=false >/dev/null && \
	  $(TF) -chdir=$$d validate; \
	done

lint:
	tflint --recursive --config=$$(pwd)/.tflint.hcl

security:
	tfsec . --soft-fail=false

# -----------------------------------------------------------------------------
# Cost (Infracost)
# -----------------------------------------------------------------------------
.PHONY: infracost-uat infracost-prod
infracost-uat:
	infracost breakdown --path $(UAT_DIR)

infracost-prod:
	infracost breakdown --path $(PROD_DIR)
