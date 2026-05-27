#!/usr/bin/env bash
# infracost-diff.sh — chạy infracost diff so với base branch.
#
# Usage:
#   infracost-diff.sh <plan_json_path>
#
# Yêu cầu env:
#   INFRACOST_API_KEY  — credential injected từ Jenkins withCredentials.
#   GITHUB_BASE_REF    — branch base của PR (e.g. 'main').
#
# Exit codes:
#   0 — diff < threshold (default $50)
#   1 — diff vượt threshold → cảnh báo (KHÔNG fail pipeline mà chỉ block UI)
#   3 — infracost lỗi runtime

set -euo pipefail

PLAN_JSON="${1:-plan.json}"
THRESHOLD_USD="${INFRACOST_THRESHOLD_USD:-50}"

if ! command -v infracost >/dev/null 2>&1; then
  echo "❌ infracost chưa được cài đặt" >&2
  exit 3
fi

if [[ -z "${INFRACOST_API_KEY:-}" ]]; then
  echo "❌ INFRACOST_API_KEY chưa set (inject qua withCredentials)" >&2
  exit 3
fi

# Chạy infracost trên plan hiện tại.
infracost breakdown --path "${PLAN_JSON}" --format json --out-file infracost-current.json

# So sánh với base branch (best-effort — nếu base không có infracost.json thì skip).
if [[ -n "${GITHUB_BASE_REF:-}" && -f ".infracost-base.json" ]]; then
  infracost diff \
    --path "${PLAN_JSON}" \
    --compare-to .infracost-base.json \
    --format diff \
    > infracost-diff.txt
  cat infracost-diff.txt
else
  echo "ℹ️ Không có baseline — chỉ in tổng cost." >&2
  infracost output --path infracost-current.json --format table
fi

# Cảnh báo nếu diff lớn.
DIFF_USD=$(jq '.totalMonthlyCost // 0 | tonumber' infracost-current.json)
if (( $(echo "${DIFF_USD} > ${THRESHOLD_USD}" | bc -l) )); then
  echo "⚠️ Cost change ${DIFF_USD} USD vượt threshold ${THRESHOLD_USD} USD" >&2
  exit 1
fi

echo "✅ Cost OK (${DIFF_USD} USD <= ${THRESHOLD_USD})"
exit 0
