## 📝 Mô tả

<!-- Tóm tắt thay đổi trong 2-3 câu. Link tới Jira / GitHub issue nếu có. -->

Closes #

## 🎯 Loại thay đổi

- [ ] `feat` — feature mới
- [ ] `fix` — sửa bug
- [ ] `chore` — refactor / dependency / docs
- [ ] `breaking` — breaking change (cần update doc + thông báo)

## ✅ Checklist trước khi merge

- [ ] Đã chạy `make lint` + `make test` local, **PASS**
- [ ] Coverage **≥ 70%** (xem `htmlcov/index.html` hoặc CI report)
- [ ] Đã thêm/cập nhật test cho code mới
- [ ] Đã update `requirements.txt` của lambda tương ứng nếu thêm dependency mới
- [ ] **KHÔNG** commit secret, AWS account ID, ARN cụ thể, hay credential
- [ ] Đã update `docs/lambda-conventions.md` nếu đổi convention chung
- [ ] Đã update README của lambda nếu thay đổi endpoint / event shape
- [ ] Branch theo convention (`feat/`, `fix/`, `chore/`)
- [ ] Commit message theo Conventional Commits (`feat(auth): ...`)

## 🧪 Test đã chạy

<!-- Lệnh đã chạy, output coverage… -->

```bash
make lint
make test
```

## 📦 Lambda bị ảnh hưởng

- [ ] `authentication_lambda`
- [ ] `notification_lambda`
- [ ] `upload_lambda`
- [ ] `compression_lambda`
- [ ] `job_status_lambda`
- [ ] `shared/` (⚠️ ảnh hưởng tất cả lambda — cần review kỹ)

## 🔍 Note cho reviewer

<!-- Chỗ nào cần chú ý đặc biệt, edge case nào đã test, deps nào nâng cấp… -->
