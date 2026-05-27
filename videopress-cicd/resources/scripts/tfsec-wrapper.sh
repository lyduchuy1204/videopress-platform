#!/usr/bin/env bash
# tfsec-wrapper.sh — chạy tfsec với exit code mapping rõ ràng.
#
# Usage:
#   tfsec-wrapper.sh <terraform_dir>
#
# Exit codes:
#   0 — không có issue HIGH/CRITICAL
#   1 — có issue HIGH/CRITICAL → fail pipeline
#   2 — chỉ có issue MEDIUM/LOW → cảnh báo, KHÔNG fail
#   3 — tfsec chạy lỗi (timeout, parse fail)

set -euo pipefail

TF_DIR="${1:-.}"
REPORT_FILE="${TFSEC_REPORT:-tfsec-report.json}"

if ! command -v tfsec >/dev/null 2>&1; then
  echo "❌ tfsec chưa được cài đặt trên runner" >&2
  exit 3
fi

echo "▶ tfsec scan: ${TF_DIR}"

set +e
tfsec "${TF_DIR}" \
  --format json \
  --out "${REPORT_FILE}" \
  --soft-fail
RC=$?
set -e

if [[ ${RC} -ne 0 && ! -f "${REPORT_FILE}" ]]; then
  echo "❌ tfsec lỗi runtime (exit ${RC})" >&2
  exit 3
fi

# Đếm severity bằng jq.
HIGH_CRIT=$(jq '[.results[]? | select(.severity=="HIGH" or .severity=="CRITICAL")] | length' "${REPORT_FILE}")
MED_LOW=$(jq   '[.results[]? | select(.severity=="MEDIUM" or .severity=="LOW")] | length'   "${REPORT_FILE}")

echo "🔍 Issues — HIGH/CRITICAL: ${HIGH_CRIT} · MEDIUM/LOW: ${MED_LOW}"

if [[ ${HIGH_CRIT} -gt 0 ]]; then
  jq '.results[] | select(.severity=="HIGH" or .severity=="CRITICAL") | {severity, rule_id, description, location}' "${REPORT_FILE}"
  exit 1
fi

if [[ ${MED_LOW} -gt 0 ]]; then
  echo "⚠️ Có ${MED_LOW} issue MEDIUM/LOW — không fail nhưng nên xem báo cáo." >&2
  exit 2
fi

echo "✅ tfsec clean"
exit 0
