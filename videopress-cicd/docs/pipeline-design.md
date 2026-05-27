# Pipeline Design Rationale

> Tại sao tách 4 Jenkinsfile + nguyên tắc concurrency, approval gate, DynamoDB safety enforcement.

---

## 1. Why 4 Jenkinsfile thay vì 1 file lớn?

| Lý do | Giải thích |
|---|---|
| **Permission khác nhau** | Job rollback chỉ SRE on-call có quyền trigger. Job plan thì mọi dev được. Tách Jenkinsfile + Folder Auth Plugin = ACL rõ. |
| **History tách bạch** | Build history Jenkins UI hiển thị job riêng cho deploy / rollback / plan. Audit log dễ đọc. |
| **Concurrency control rõ** | `Jenkinsfile.deploy` cần `lock('${env}-deploy')`. `Jenkinsfile.plan` không cần (build song song nhiều PR). |
| **Reusable** | Mỗi Jenkinsfile chỉ 5-15 dòng gọi DSL. Repo khác paste là dùng được. |
| **Test riêng** | Có thể `replay` từng pipeline trên Jenkins UI mà không ảnh hưởng pipeline khác. |
| **Parameterization** | Parameter của 4 pipeline khác nhau (rollback có `target_state_version_id`, deploy không). Tách = UI gọn. |

### 4 Jenkinsfile chính + 2 bonus

| File | Trigger | Owner |
|---|---|---|
| `Jenkinsfile.ci` (gọi `pythonLambdaPipeline`) | PR mở/push backend | Backend dev |
| `Jenkinsfile.plan` (gọi `terraformPlanPipeline`) | PR mở/push IaC | DevOps |
| `Jenkinsfile.deploy` (gọi `terraformDeployPipeline`) | Merge main, tag | DevOps + SRE |
| `Jenkinsfile.rollback` (gọi `terraformRollbackPipeline`) | Manual UI | SRE only |
| `Jenkinsfile.smoke-test` (gọi `smokeTestPipeline`) | Downstream sau deploy | DevOps |
| `Jenkinsfile.layer-build` | Path-based filter `layer/**` | Backend dev |

---

## 2. Concurrency control

### `lock()` strategy

```groovy
// terraformDeployPipeline
lock(resource: "${env}-deploy", inversePrecedence: true) {
  applyRunner.apply(...)
}

// terraformRollbackPipeline
lock(resource: "${env}-rollback", inversePrecedence: true) {
  applyRunner.apply(...)
}
```

**Quy tắc**:
- 1 deploy/env tại 1 thời điểm.
- Rollback và deploy CÙNG ENV cũng block nhau (cùng `lock` family).
- `inversePrecedence: true` — build mới có ưu tiên cao hơn build chờ → rollback emergency không kẹt sau deploy.

### `disableConcurrentBuilds()` ở plan pipeline

`terraformPlanPipeline` set `disableConcurrentBuilds(abortPrevious: true)` → push commit mới abort plan cũ trên cùng PR. Tiết kiệm runner, giảm rác comment PR.

---

## 3. Approval gate logic

### Matrix

| Env | Auto / Manual | Số reviewer | Cooldown | Backup trước apply |
|---|---|---|---|---|
| **UAT** | Auto sau merge main | 0 | 0 phút | Không |
| **Staging** | Tag `vX.Y.Z-staging` | 1 (`devops-leads`) | 0 | State backup |
| **Prod** | Tag `vX.Y.Z` | 2 (`devops-leads` + `sre-oncall`) | **30 phút** | State + DynamoDB backup |

### Vì sao có cooldown 30 phút cho prod?

- Chống deploy panic (vừa khám phá lỗi → cuống → push fix → merge → deploy ngay → đè lỗi mới).
- Cho reviewer thời gian đọc plan kỹ.
- Cho on-call đủ thời gian dừng lại nếu phát hiện vấn đề.

### Submitter list — cấu hình ở Jenkins

```
Manage Jenkins → Manage Users / Roles
  Group: devops-leads     → 3 người
  Group: sre-oncall       → 5 người (rotate weekly)
  Group: engineering-managers → 2 người (cho rollback)
```

---

## 4. DynamoDB safety enforcement

7 nguyên tắc (xem README.md) được enforce ở các điểm sau:

| Nguyên tắc | Enforce ở đâu | Cách check |
|---|---|---|
| 1. `prevent_destroy = true` | `terraformPlanPipeline` stage 'Plan Review' | `PlanReviewBot.analyze()` check `change.actions == ['delete', 'create']` |
| 2. `deletion_protection_enabled = true` | `tflint` custom rule | Custom rule trong `.tflint.hcl` |
| 3. PITR bật | `tfsec` custom check | Custom check Rego |
| 4. Plan review 2 mắt | `terraformPlanPipeline` + GitHub branch protection | `PlanReviewBot.commentToPR()` + require 2 reviewer |
| 5. Snapshot trước apply prod | `terraformDeployPipeline` stage 'Backup DynamoDB' | `aws dynamodb create-backup` |
| 6. IAM Role per env | `AssumeRole.withOidc()` | Role ARN khác cho mỗi env |
| 7. Backup state | `S3StateBackup.backupBeforeApply()` | Upload `terraform.tfstate` lên `videopress-state-archive` với timestamp |

### `PlanReviewBot.analyze()` decision tree

```
plan.json
  └─► resource_changes filter type='aws_dynamodb_table'
      ├─► any actions == ['delete']                       → dynamoDestroy = true → BLOCK
      ├─► any actions == ['delete', 'create']             → dynamoSchemaChange = true → BLOCK
      ├─► hash_key/range_key thay đổi                     → dynamoSchemaChange = true → BLOCK
      └─► chỉ update attribute non-key                    → cho qua, comment cảnh báo
```

---

## 5. Bonus pipelines

Không bắt buộc nhưng nên có khi project trưởng thành:

| Pipeline | Mục đích | Trigger |
|---|---|---|
| `Jenkinsfile.drift-detect` | Phát hiện drift giữa tfstate và AWS thật | Cron nightly |
| `Jenkinsfile.cost-report` | Gửi infracost report cho team finance | Cron weekly |
| `Jenkinsfile.dynamodb-pitr-restore` | Tự động restore từ PITR khi runbook trigger | Manual (lồng trong rollback) |
| `Jenkinsfile.security-scan` | Chạy `checkov`, `prowler` | Cron weekly |

---

## 6. Failure handling

| Failure | Hành động |
|---|---|
| Apply lỗi giữa chừng | **KHÔNG auto rollback** — có thể tệ thêm. Notify on-call qua Teams. |
| Smoke test fail sau apply | Trigger `Jenkinsfile.rollback` thủ công sau khi confirm với on-call. |
| Plan có DynamoDB schema change | Pipeline fail ở stage 'Plan Review'. PR bị chặn merge qua GitHub check. |
| Approval timeout (1h staging, 2h prod) | Build tự động ABORT. Không apply. |
| Cooldown bị skip (không nên) | Chỉ admin Jenkins mới override được qua replay — log audit. |
