## 📋 Mô tả PR

<!-- 2-3 câu: thay đổi gì? Lý do? Liên quan ticket nào? -->

**Ticket**: <!-- Jira/GitHub issue link -->

**Loại thay đổi** (check 1):

- [ ] 🆕 New feature (resource mới)
- [ ] 🔧 Refactor module (không thay behavior runtime)
- [ ] 🐛 Bugfix
- [ ] 🚨 Hotfix prod
- [ ] 📚 Docs / README only
- [ ] ⚙️ CI/CD / Jenkinsfile

---

## 🌐 Môi trường ảnh hưởng

- [ ] UAT (`envs/uat`)
- [ ] Staging (`envs/staging`)
- [ ] **Prod (`envs/prod`)** ⚠️ — yêu cầu **2 reviewer** + RFC link bên dưới
- [ ] Bootstrap (`bootstrap/`) — chỉ chạy 1 lần per account
- [ ] Module (`modules/...`) — ảnh hưởng tất cả env

---

## ⚠️ Câu hỏi BẮT BUỘC trả lời

### 1. Plan có resource bị **destroy** không?

- [ ] Không có resource bị destroy.
- [ ] **CÓ** — liệt kê:
  - `aws_xxx.yyy` — lý do: ...
  - Đã backup chưa? Có versioning/PITR không?

### 2. Plan có resource bị **replace** (forces new resource) không?

- [ ] Không có resource bị replace.
- [ ] **CÓ** — liệt kê:
  - `aws_xxx.yyy` — vì attribute `zzz` thay đổi (immutable).
  - Có downtime không? Bao lâu?

### 3. Có động vào **DynamoDB table** không?

- [ ] Không.
- [ ] **CÓ** — check kỹ:
  - [ ] KHÔNG đổi `hash_key` / `range_key` / `attribute` schema (sẽ replace = MẤT DATA).
  - [ ] PITR vẫn bật.
  - [ ] `deletion_protection_enabled = true` ở Staging/Prod.
  - [ ] Có `prevent_destroy` lifecycle ở Prod.
  - [ ] Đã ping `@videopress-org/sre-oncall` review.

### 4. Có động vào **state file** (rename, move, import) không?

- [ ] Không.
- [ ] **CÓ** — đính kèm:
  - Script `terraform state mv ...` đã chạy ở local (chưa apply prod).
  - Backup state pre-change đã upload `videopress-state-archive`.

### 5. Có thay đổi **IAM/security/KMS/bucket policy** không?

- [ ] Không.
- [ ] **CÓ** — review bởi `@videopress-org/security-team`.

---

## 🧪 Đã test

- [ ] `terraform fmt` clean
- [ ] `terraform validate` pass
- [ ] `tflint --recursive` pass
- [ ] `tfsec` pass (hoặc đã giải thích các finding accepted)
- [ ] `terraform plan` đã review — paste vào comment Jenkins
- [ ] Đã chạy trên UAT thành công (nếu áp dụng)

---

## 📈 Cost impact (Infracost)

<!-- Bot Jenkins sẽ comment infracost diff. Note bất kỳ thay đổi > $20/tháng. -->

---

## 🔗 RFC / Design doc (bắt buộc cho PR Prod)

<!-- Link Confluence/Notion ADR -->

---

## ✅ Reviewer checklist

- [ ] Plan trông hợp lý, không có "lụi" nhầm resource khác
- [ ] Tag bắt buộc đầy đủ (`Project`, `Environment`, `Owner`, `ManagedBy`, `CostCenter`)
- [ ] Comment Terraform giải thích logic (đặc biệt phần phức tạp)
- [ ] README module đã update (nếu sửa module)
