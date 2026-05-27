# On-call Runbook — VideoPress Platform

> Playbook khi prod sự cố. Đọc kỹ trước khi vào on-call rotation lần đầu.

---

## 0. Trước khi đọc tiếp

- [ ] Bạn đã được add vào Jenkins group `sre-oncall`.
- [ ] Bạn có account PagerDuty và đã test trigger.
- [ ] Bạn có quyền Read/Write `videopress/` folder Jenkins.
- [ ] Bạn đã đọc `pipeline-design.md` + `secrets-management.md`.
- [ ] Bạn đã chạy thử rollback ở **staging** ít nhất 1 lần (drill).

---

## 1. Severity matrix

| Severity | Định nghĩa | Response time | Communication |
|---|---|---|---|
| **SEV1** | Prod down toàn bộ — user không dùng được core feature (upload, login). | 15 phút | Page on-call + #videopress-sre + Status page |
| **SEV2** | Prod degraded — 1 endpoint chậm/lỗi nhưng workaround. | 30 phút | #videopress-sre |
| **SEV3** | Prod có lỗi nhỏ — có thể đợi giờ hành chính. | 4h | Ticket Jira |
| **SEV4** | Non-prod (UAT/Staging) lỗi. | Next day | Ticket Jira |

---

## 2. Communication template (Microsoft Teams)

### 2.1. Khi mới phát hiện (T+0)

```
🚨 [SEV1] VideoPress Prod — <short description>
Detected at: <UTC timestamp>
Symptom: <1 dòng>
Impact: <user count / feature>
On-call: <@your-name>
Action: Investigating. Update in 15 min.
```

### 2.2. Update giữa incident (T+15, T+30)

```
🔄 [SEV1 update] <hh:mm>
Status: <investigating | mitigating | resolved>
Action taken: <list>
Next step: <list>
ETA mitigation: <hh:mm>
```

### 2.3. Sau khi mitigate (T+resolved)

```
✅ [SEV1 resolved] <hh:mm>
Duration: <minutes>
Mitigation: <e.g. rollback to v1.2.3>
Root cause: TBD (post-mortem trong 48h)
PM doc: <link>
```

---

## 3. Rollback decision tree

```
Prod 5xx alarm bắn
  │
  ├─► Lỗi xuất hiện ngay sau deploy gần nhất (< 15 phút)?
  │   ├─► YES → ROLLBACK ngay (Jenkinsfile.rollback)
  │   └─► NO  → đi nhánh dưới
  │
  ├─► Lỗi do code Lambda?
  │   ├─► YES → Rollback Lambda alias `live` về version trước (CLI:
  │   │         `aws lambda update-alias --function-name X --name live --function-version <prev>`)
  │   └─► NO  → đi nhánh dưới
  │
  ├─► Lỗi do schema DynamoDB?
  │   ├─► YES → Restore PITR (xem mục 4)
  │   └─► NO  → escalate Engineering Manager
  │
  └─► Lỗi do third-party (Cognito, S3, ...)?
      └─► Check AWS Health Dashboard, mở Support case Severity Business
```

---

## 4. Rollback steps — Jenkinsfile.rollback

### B1. Vào Jenkins UI

```
Jenkins → videopress / videopress-infrastructure / Jenkinsfile.rollback
→ Build with Parameters
```

### B2. Điền parameter

| Param | Giá trị |
|---|---|
| `TARGET_ENV` | `prod` |
| `TARGET_STATE_VERSION_ID` | (lấy từ stage 'List versions' của job, paste sau khi build chạy đến đó) |
| `REASON` | "Rollback do incident INC-123 — 5xx alarm prod" |
| `INCIDENT_TICKET` | `https://videopress.atlassian.net/browse/INC-123` |
| `RESTORE_DYNAMODB_PITR` | ☐ (chỉ tick khi schema DynamoDB cũng cần restore) |

### B3. Approval 1 (trước khi tải state cũ)

- Confirm với approver thứ 2 qua Teams trước khi click Approve.

### B4. Đọc plan ở stage 'Init + Plan'

- Tải `plan-readable.txt` từ artifact.
- Verify: số resource bị thay đổi có khớp với expectation? Nếu KHÔNG khớp → ABORT, escalate.

### B5. Approval 2 (apply)

- Đọc plan kỹ → click Approve.

### B6. Sau apply

- Smoke test stage tự chạy. Nếu fail → escalate ngay.
- Audit log tự upload lên `s3://videopress-audit-trail/rollbacks/`.

---

## 5. Restore DynamoDB từ PITR

> ⚠️ Mất 5-30 phút tuỳ size table. KHÔNG restore lên cùng tên table — phải restore lên table tạm.

```bash
# 1. Xác định timestamp restore (UTC, ISO 8601).
RESTORE_TIME="2025-01-15T10:30:00Z"
TABLE="Users-prod"
RESTORED_TABLE="${TABLE}-restored-$(date +%s)"

# 2. Restore.
aws dynamodb restore-table-to-point-in-time \
  --source-table-name "${TABLE}" \
  --target-table-name "${RESTORED_TABLE}" \
  --restore-date-time "${RESTORE_TIME}" \
  --use-latest-restorable-time

# 3. Đợi ACTIVE.
aws dynamodb wait table-exists --table-name "${RESTORED_TABLE}"

# 4. Verify count + sample data.
aws dynamodb scan --table-name "${RESTORED_TABLE}" --select COUNT
aws dynamodb scan --table-name "${RESTORED_TABLE}" --max-items 5

# 5. Swap tên qua DNS layer (alias) — Lambda code đọc env var TABLE_NAME.
# KHÔNG xoá table cũ ngay — giữ 7 ngày phòng cần đối chiếu.
```

---

## 6. Post-mortem template

Mở doc trong 48h sau incident, share trong `#videopress-sre`.

```markdown
# Post-mortem: <SEV-X> <short title> — YYYY-MM-DD

## Summary
<2-3 câu mô tả lỗi.>

## Timeline (UTC)
| Time | Event |
|---|---|
| 10:00 | Deploy v1.2.3 → prod |
| 10:15 | Alarm 5xx fire |
| 10:18 | On-call paged |
| 10:25 | Rollback approved |
| 10:32 | Rollback complete, alarm clear |

## Impact
- User affected: ~X% trong Y phút.
- Revenue / SLA breach: <số liệu>.

## Root cause
<Mô tả kỹ thuật. KHÔNG đổ lỗi cho người.>

## What went well
- ...

## What went poorly
- ...

## Action items
| # | Action | Owner | Due |
|---|---|---|---|
| 1 | Add unit test cho case X | <name> | YYYY-MM-DD |
| 2 | Update runbook section Y | <name> | YYYY-MM-DD |

## Lessons learned
<1-2 đoạn cho team-wide reading.>
```

---

## 7. Liên hệ khẩn cấp

| Vai trò | Cách gọi |
|---|---|
| Engineering Manager | PagerDuty escalation policy `videopress-em` |
| AWS TAM (nếu có Enterprise Support) | Phone trong Support case Severity Critical |
| Security on-call | Slack `#security-oncall` + page qua PagerDuty |
| Legal / Compliance (data leak) | Email `legal@videopress.example.com` |

---

## 8. Drill / chaos schedule

- **Hàng quý**: rollback drill ở **staging** — 1 SRE thực hiện end-to-end, đo thời gian.
- **Hàng năm**: simulate prod incident trong giờ work, không thông báo trước (chỉ EM biết).
