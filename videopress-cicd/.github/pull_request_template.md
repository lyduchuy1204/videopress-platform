# Pull Request — videopress-cicd

## 📝 Mô tả

<!-- Tóm tắt thay đổi trong 2-3 câu. Tại sao cần thay đổi này? -->

## 🔗 Liên kết

- Jira / Linear ticket: `VID-____`
- RFC (nếu là breaking change): _link_
- Issue liên quan: #____

## 📂 Scope thay đổi

- [ ] `vars/` — pipeline DSL global function
- [ ] `src/com/videopress/aws/` — AWS interaction
- [ ] `src/com/videopress/notify/` — notification
- [ ] `src/com/videopress/terraform/` — Terraform helper
- [ ] `pipelines/*.sample` — Jenkinsfile mẫu
- [ ] `resources/templates/` — message template
- [ ] `docs/` — tài liệu
- [ ] Build config (`build.gradle`, `settings.gradle`)
- [ ] CHANGELOG.md

## ✅ Checklist

- [ ] Đã viết Spock spec cho class/function mới.
- [ ] Coverage ≥ 80% (xem JaCoCo report).
- [ ] CodeNarc lint pass — `./gradlew codenarcMain codenarcTest`.
- [ ] Đã chạy local: `./gradlew check` xanh.
- [ ] Update CHANGELOG.md section `[Unreleased]`.
- [ ] Update README.md / docs nếu thay đổi DSL signature.
- [ ] Validate parameter ở đầu mỗi DSL function (`assert config.foo : "..."`).
- [ ] Không hardcode webhook URL, role ARN, token (dùng `env.*` hoặc `config.*`).
- [ ] Có `try/finally` cleanup credentials khi dùng `withCredentials`.

## 🔬 Cách test

<!-- Lệnh / step để reviewer reproduce -->

```bash
./gradlew test
./gradlew jacocoTestReport
```

## 🚨 Breaking change?

- [ ] **KHÔNG** breaking — bump PATCH/MINOR.
- [ ] **CÓ** breaking — bump MAJOR. Đã update CHANGELOG section "Migration guide".

## 👀 Reviewer cần check kỹ

<!-- Highlight phần nào reviewer cần xem kỹ. Ví dụ: logic phát hiện DynamoDB schema change. -->
