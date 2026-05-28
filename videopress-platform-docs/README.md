# 📄 videopress-platform-docs

> **Documentation hub** cho VideoPress Platform — Architecture diagrams, ADR (Architecture Decision Records), runbook, OpenAPI spec.

[![Status](https://img.shields.io/badge/status-active-brightgreen)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

---

## 📑 Mục lục

1. [Mục đích](#-mục-đích)
2. [Khi nào tạo repo này](#-khi-nào-tạo-repo-này)
3. [Cấu trúc](#-cấu-trúc-folder)
4. [Architecture Decision Records (ADR)](#-architecture-decision-records-adr)
5. [Runbook](#-runbook)
6. [API Spec](#-api-spec)
7. [Diagrams](#-diagrams)
8. [Cách contribute](#-cách-contribute)
9. [Owner & Contact](#-owner--contact)
10. [Cross-repo links](#-cross-repo-links)

---

## 🎯 Mục đích

Repo này tập trung **tài liệu mức platform** — không thuộc về 1 codebase nào riêng lẻ:

- **ADR** (Architecture Decision Records): ghi chép các quyết định kiến trúc lớn + lý do.
- **Runbook**: hướng dẫn vận hành (deploy prod, rollback, on-call handover, incident).
- **API spec**: OpenAPI 3.1 spec sinh từ code backend (single source of truth cho client/SDK).
- **Diagrams**: sơ đồ kiến trúc bằng draw.io (export PNG kèm theo).

> 💡 Tách repo riêng vì: (a) tài liệu thay đổi với cadence khác code, (b) writer team khác coder team, (c) diagram binary file (`.drawio`, `.png`) làm `git diff` repo code rối.

---

## 📅 Khi nào tạo repo này

Repo này **OPTIONAL** trong scaffold VideoPress Platform — KHÔNG nằm trong 4 phase chính.

| Điều kiện | Tạo ngay? |
|---|---|
| Team < 3 người, chỉ 1 dự án | ❌ Nhúng `docs/` vào root meta — không cần repo riêng |
| Team 3-5 người, có DevOps + Backend | ⚠️ Optional — có thể đợi tới khi có ≥ 5 ADR |
| Team > 5 người, hoặc compliance audit | ✅ Tạo ngay từ Phase 1 |
| Sau Phase 4 đã chạy ổn (~tuần 5+) | ✅ Tạo lúc này hợp lý nhất — đã có thực tế để viết ADR |

---

## 📂 Cấu trúc folder

```
videopress-platform-docs/
├── README.md                          ← bạn đang đọc
├── ARCHITECTURE.md                    ← high-level architecture overview (single page)
├── adr/                               ← Architecture Decision Records
│   ├── README.md                      ← index ADR + template
│   ├── 0001-multi-repo-vs-monorepo.md
│   ├── 0002-private-api-via-vpce.md
│   ├── 0003-cognito-vs-custom-auth.md
│   ├── 0004-jenkins-vs-github-actions.md
│   ├── 0005-dynamodb-billing-mode.md
│   └── 0006-network-isolation.md      ← 3 VPC tách biệt
├── runbook/
│   ├── README.md                      ← index runbook
│   ├── deploy-prod.md
│   ├── rollback-procedure.md
│   ├── on-call-handover.md
│   └── incident-template.md
├── api/
│   ├── README.md                      ← cách sinh + version OpenAPI spec
│   └── openapi.yaml                   ← OpenAPI 3.1 (sinh từ code backend)
└── diagrams/
    ├── README.md                      ← convention: tên file, format export
    ├── architecture-overall.drawio
    ├── architecture-overall.png
    ├── data-flow-compression.drawio
    ├── data-flow-compression.png
    ├── network-vpc-endpoint.drawio
    └── network-vpc-endpoint.png
```

---

## 📖 Architecture Decision Records (ADR)

ADR ghi lại các **quyết định kiến trúc quan trọng** + bối cảnh + lý do chọn (không phải hướng dẫn how-to).

### Format chuẩn

Mỗi ADR là 1 file Markdown đặt tên `<số>-<slug>.md`:

```markdown
# ADR-XXXX: <Tiêu đề ngắn>

**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-YYYY
**Date**: YYYY-MM-DD
**Decision-makers**: @user1, @user2

## Context
Bối cảnh, vấn đề cần giải quyết.

## Options considered
- Option A: ... — pros/cons
- Option B: ... — pros/cons
- Option C: ... — pros/cons

## Decision
Chốt option B vì lý do ...

## Consequences
Tích cực: ...
Tiêu cực: ...
Trung tính: ...

## References
- Link tài liệu, RFC, blog post liên quan.
```

### ADR hiện có (cập nhật từ IDEA.md)

| # | Quyết định | Status |
|---|---|---|
| 0001 | Multi-repo vs Monorepo | Accepted |
| 0002 | Private API qua VPCE thay vì Public API + WAF | Accepted |
| 0003 | Cognito User Pool thay vì custom auth | Accepted |
| 0004 | Jenkins thay vì GitHub Actions | Accepted |
| 0005 | DynamoDB billing PAY_PER_REQUEST | Accepted |
| 0006 | Network isolation — 3 VPC riêng cho 3 env | Accepted |

> 💡 **Quy tắc**: ADR đã `Accepted` thì **KHÔNG sửa** — nếu thay đổi quyết định, viết ADR mới với status `Supersedes ADR-XXXX`.

---

## 📕 Runbook

Hướng dẫn vận hành step-by-step. Khác ADR ở chỗ: ADR nói "vì sao", Runbook nói "làm thế nào".

| File | Khi nào dùng |
|---|---|
| `deploy-prod.md` | Mỗi lần deploy Prod — checklist trước/trong/sau |
| `rollback-procedure.md` | Khi prod hỏng — flowchart 4 chiến lược rollback |
| `on-call-handover.md` | Khi đổi shift on-call — context cần truyền |
| `incident-template.md` | Khi có incident — template post-mortem |

> 💡 Runbook **phải được test thực tế** ít nhất 1 lần (game day). Runbook không test = runbook giả.

---

## 🔌 API Spec

`api/openapi.yaml` là **single source of truth** cho mọi REST API VideoPress.

### Sinh OpenAPI từ code backend

```bash
cd ../videopress-backend
make openapi
# Output: ../videopress-platform-docs/api/openapi.yaml
```

### Validate

```bash
npx @redocly/cli lint api/openapi.yaml
```

### Generate client SDK

```bash
# Python client
openapi-generator-cli generate -i api/openapi.yaml -g python -o ../sdk-python/

# TypeScript client
openapi-generator-cli generate -i api/openapi.yaml -g typescript-axios -o ../sdk-typescript/
```

> ⚠️ **Versioning**: tag OpenAPI spec cùng version với backend (`openapi-v1.2.3`) để client biết tương thích nào.

---

## 🎨 Diagrams

Convention:
- **Source format**: `.drawio` (mở bằng draw.io desktop hoặc plugin VS Code).
- **Export format**: `.png` cùng tên (kèm trong commit để GitHub render được trong Markdown).
- **Naming**: kebab-case mô tả nội dung (`data-flow-compression.drawio`, KHÔNG đặt `diagram1.drawio`).

### Workflow update diagram

```bash
# 1. Sửa file .drawio
# 2. Export PNG cùng tên
# 3. Commit cả 2 file
git add diagrams/data-flow-compression.drawio diagrams/data-flow-compression.png
git commit -m "docs(diagram): update compression flow with retry logic"
```

---

## 🤝 Cách contribute

### Branching

- `main` — branch chính, chỉ merge qua PR.
- Feature branch: `docs/add-adr-0007-mediaconvert`, `docs/update-runbook-rollback`.

### PR template

PR vào repo này tự load `.github/pull_request_template.md` với checklist:
- [ ] ADR mới có đủ context + options + decision + consequences?
- [ ] Runbook đã test thực tế chưa?
- [ ] Diagram đã export PNG chưa?
- [ ] Link cross-repo (backend / IaC / cicd) đã verify?

### Review

- ADR mức platform: cần approve từ **Engineering Manager + Tech Lead**.
- Runbook: cần approve từ **SRE on-call**.
- Diagram + API spec: cần approve từ **owner repo backend hoặc IaC**.

---

## 👥 Owner & Contact

- **Primary owner**: Platform Engineering team
- **ADR reviewer**: Engineering Manager (`@em-name`)
- **Runbook reviewer**: SRE Lead (`@sre-lead-name`)
- **Slack channel**: `#videopress-platform`
- **Office hour**: Thứ 5 hàng tuần, 14:00-15:00

---

## 🔗 Cross-repo links

| Repo | Vai trò | Link |
|---|---|---|
| `videopress-backend` | Python Lambda code | [`../videopress-backend`](../videopress-backend/) |
| `videopress-infrastructure` | Terraform IaC | [`../videopress-infrastructure`](../videopress-infrastructure/) |
| `videopress-cicd` | Jenkins Shared Library | [`../videopress-cicd`](../videopress-cicd/) |
| **IDEA gốc** | High-level design | [`../IDEA.md`](../IDEA.md) |

---

## 📜 License

MIT — dùng tự do cho học tập + nội bộ team.
