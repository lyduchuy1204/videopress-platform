# 🤖 videopress-cicd — Jenkins Shared Library

[![Jenkins](https://img.shields.io/badge/Jenkins-2.426.x-blue?logo=jenkins)](https://www.jenkins.io/)
[![Groovy](https://img.shields.io/badge/Groovy-3.0.19-4298B8?logo=apachegroovy)](https://groovy-lang.org/)
[![Spock](https://img.shields.io/badge/Spock-2.3-0a7bbb)](https://spockframework.org/)
[![Gradle](https://img.shields.io/badge/Gradle-8.x-02303A?logo=gradle)](https://gradle.org/)
[![License](https://img.shields.io/badge/License-Apache--2.0-green.svg)](LICENSE)
[![Coverage](https://img.shields.io/badge/coverage-%E2%89%A580%25-brightgreen)](#)

> **Repo 3 / 3 của VideoPress Platform** — Jenkins Shared Library + Jenkinsfile templates dùng chung cho mọi pipeline (backend Python Lambda, IaC Terraform, smoke test, rollback).
>
> Owner: **SRE / DevOps team**.

---

## 📑 Mục lục

- [🎯 Mục đích](#-mục-đích)
- [🏗️ Tech stack](#️-tech-stack)
- [📂 Cấu trúc folder](#-cấu-trúc-folder)
- [🚀 Quick start — cài shared library trong Jenkins](#-quick-start--cài-shared-library-trong-jenkins)
- [🧪 Cách test shared library](#-cách-test-shared-library)
- [📋 Pipeline DSL functions](#-pipeline-dsl-functions)
- [🛡️ DynamoDB safety — 7 nguyên tắc](#️-dynamodb-safety--7-nguyên-tắc)
- [🔐 Secrets management](#-secrets-management)
- [🔄 Versioning & release](#-versioning--release)
- [📝 Add new pipeline DSL — step-by-step](#-add-new-pipeline-dsl--step-by-step)
- [🤝 Contributing](#-contributing)
- [👥 Owner](#-owner)
- [🔗 Liên kết các repo consumer](#-liên-kết-các-repo-consumer)

---

## 🎯 Mục đích

Repo này chứa **toàn bộ logic CI/CD** dùng chung cho stack VideoPress Platform:

1. **Pipeline DSL** (`vars/*.groovy`) — function global gọi từ `Jenkinsfile` của repo consumer chỉ với 3-5 dòng.
2. **Helper class** (`src/com/videopress/**`) — tách logic AWS, notify, terraform thành class testable bằng Spock.
3. **Jenkinsfile templates** (`pipelines/*.sample`) — file mẫu để consumer copy & paste, sửa config.
4. **Resources** (`resources/templates/`, `resources/scripts/`) — template comment PR, bash wrapper.
5. **Docs** (`docs/`) — design rationale, secrets, on-call runbook.

> 💡 Nguyên tắc: **không repo nào tự viết Jenkinsfile dài**. Tất cả logic phức tạp (approval gate, DynamoDB safety check, state backup) nằm ở đây để áp dụng nhất quán.

---

## 🏗️ Tech stack

| Layer | Tool | Version |
|---|---|---|
| CI server | Jenkins | 2.426.x LTS |
| Language | Groovy | 3.0.19 |
| Test framework | Spock | 2.3-groovy-3.0 |
| Pipeline unit test | jenkins-pipeline-unit | 1.18 |
| Build | Gradle | 8.x |
| Static analysis | CodeNarc | 3.4.0 |
| Coverage | JaCoCo | 0.8.x |
| Lint Terraform | tflint, tfsec | latest |
| Cost diff | infracost | latest |

---

## 📂 Cấu trúc folder

```
videopress-cicd/
├── README.md                          ← bạn đang đọc
├── Jenkinsfile                        ← test chính shared library (./gradlew test)
├── build.gradle                       ← Gradle config
├── settings.gradle
├── CHANGELOG.md
├── VERSIONING.md
├── .gitignore
├── .github/
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── vars/                              ← Pipeline DSL global functions
│   ├── pythonLambdaPipeline.groovy
│   ├── terraformPlanPipeline.groovy
│   ├── terraformDeployPipeline.groovy
│   ├── terraformRollbackPipeline.groovy
│   └── smokeTestPipeline.groovy
├── src/
│   ├── com/videopress/
│   │   ├── aws/
│   │   │   ├── AssumeRole.groovy
│   │   │   └── S3StateBackup.groovy
│   │   ├── notify/
│   │   │   ├── Slack.groovy
│   │   │   └── Teams.groovy
│   │   └── terraform/
│   │       ├── PlanRunner.groovy
│   │       ├── ApplyRunner.groovy
│   │       └── PlanReviewBot.groovy   ← class quan trọng nhất
│   └── test/
│       ├── groovy/com/videopress/
│       │   ├── aws/AssumeRoleSpec.groovy
│       │   └── terraform/PlanReviewBotSpec.groovy
│       └── resources/fixtures/
│           └── plan-with-dynamodb-destroy.json
├── resources/
│   ├── templates/
│   │   ├── plan-comment.md.tpl
│   │   ├── slack-deploy.json.tpl
│   │   └── teams-deploy.json.tpl
│   └── scripts/
│       ├── tfsec-wrapper.sh
│       └── infracost-diff.sh
├── pipelines/                         ← Jenkinsfile mẫu (consumer copy)
│   ├── Jenkinsfile.backend.ci.sample
│   ├── Jenkinsfile.iac.plan.sample
│   ├── Jenkinsfile.iac.deploy.sample
│   ├── Jenkinsfile.iac.rollback.sample
│   ├── Jenkinsfile.smoke-test.sample
│   └── Jenkinsfile.layer-build.sample
└── docs/
    ├── pipeline-design.md
    ├── secrets-management.md
    └── on-call-runbook.md
```

---

## 🚀 Quick start — cài shared library trong Jenkins

### B1. Cấu hình Global Pipeline Library

Trên Jenkins controller:

```
Jenkins → Manage Jenkins → Configure System → Global Pipeline Libraries
  Name:                videopress-cicd
  Default version:     main
  Load implicitly:     ☐ (KHÔNG tick — bắt mỗi Jenkinsfile khai báo @Library tường minh)
  Allow default version override: ☑
  Retrieval method:    Modern SCM
    → Git
       Project Repository: https://github.com/videopress/videopress-cicd.git
       Credentials:        github-readonly-pat
```

### B2. Khai báo trong Jenkinsfile của repo consumer

```groovy
@Library('videopress-cicd@v1.2.0') _   // pin version cho prod
// hoặc:
@Library('videopress-cicd@main') _     // dev / luôn lấy bản mới nhất

pythonLambdaPipeline(
  pythonVersion: '3.11',
  coverageThreshold: 70,
  lambdas: ['hello', 'auth-issue', 'video-create-job'],
  artifactBucket: 'videopress-artifacts-non-prod',
  teamsWebhook: env.TEAMS_WEBHOOK_BACKEND
)
```

### B3. Tag version mới khi release

```bash
git tag -a v1.2.0 -m "Add prod cooldown gate"
git push origin v1.2.0
```

> ⚠️ **Đừng dùng `@main` cho prod pipeline** — bị break khi PR mới merge. Luôn pin tag.

---

## 🧪 Cách test shared library

### Local

```bash
./gradlew test                # chạy Spock spec
./gradlew codenarcMain        # lint Groovy
./gradlew jacocoTestReport    # coverage report
./gradlew check               # tất cả gộp lại
```

Mở report: `build/reports/tests/test/index.html`, `build/reports/jacoco/test/html/index.html`.

### CI

`Jenkinsfile` ở root repo này chạy `./gradlew test` mỗi PR mở/push. Build phải xanh trước khi merge.

### Test pipeline DSL với jenkins-pipeline-unit

Xem `src/test/groovy/com/videopress/terraform/PlanReviewBotSpec.groovy` — mock pipeline step `sh`, `readFile`, `error` để test logic trong Groovy class thuần.

---

## 📋 Pipeline DSL functions

| Function | File | Mục đích | Dùng ở repo |
|---|---|---|---|
| `pythonLambdaPipeline(config)` | `vars/pythonLambdaPipeline.groovy` | Lint + pytest + coverage + build zip + push artifact cho repo Python Lambda | `videopress-backend` |
| `terraformPlanPipeline(config)` | `vars/terraformPlanPipeline.groovy` | fmt + init + validate + tflint + tfsec + plan + comment PR + chặn DynamoDB schema change | `videopress-infrastructure` (PR) |
| `terraformDeployPipeline(config)` | `vars/terraformDeployPipeline.groovy` | Apply theo env, có approval gate (UAT auto, Staging 1 approval, Prod 2 approval + backup) | `videopress-infrastructure` (merge main / tag) |
| `terraformRollbackPipeline(config)` | `vars/terraformRollbackPipeline.groovy` | Khôi phục state từ S3 versioning, 2 approval, audit log | `videopress-infrastructure` (manual) |
| `smokeTestPipeline(config)` | `vars/smokeTestPipeline.groovy` | Chạy Postman/curl test sau deploy | `videopress-infrastructure` (downstream) |

Xem `pipelines/*.sample` để biết cách gọi.

---

## 🛡️ DynamoDB safety — 7 nguyên tắc

Repo này **enforce** 7 nguyên tắc dưới đây qua pipeline DSL. Vi phạm = pipeline fail.

1. **`prevent_destroy = true`** ở Terraform lifecycle cho mọi DynamoDB table prod (check ở `terraformPlanPipeline`).
2. **`deletion_protection_enabled = true`** ở AWS API layer.
3. **PITR bật toàn thời gian** — verify trong plan output.
4. **Plan review 2 mắt** — `PlanReviewBot.analyze()` parse `plan.json` và:
   - Phát hiện `~ hash_key` / `~ range_key` → `dynamoSchemaChange = true` → **CHẶN merge**.
   - Phát hiện `- aws_dynamodb_table` → `dynamoDestroy = true` → đòi 2 reviewer + RFC link.
   - Comment summary lên PR qua `commentToPR()`.
5. **Snapshot trước apply prod** — `terraformDeployPipeline` tự gọi `aws dynamodb create-backup` trước khi `terraform apply`.
6. **IAM Role per env** — runner UAT KHÔNG có quyền chạm DynamoDB prod (dùng `AssumeRole.withOidc()`).
7. **Backup state trước apply** — `S3StateBackup.backupBeforeApply()` upload `terraform.tfstate` lên `videopress-state-archive` với timestamp.

> 📖 Đọc thêm: [`docs/pipeline-design.md`](docs/pipeline-design.md) phần "DynamoDB safety enforcement".

### Detection logic (PlanReviewBot)

```groovy
// src/com/videopress/terraform/PlanReviewBot.groovy
Map analyze(String planJsonPath) {
  def plan = new JsonSlurper().parse(new File(planJsonPath))
  def changes = plan.resource_changes ?: []

  def dynamoTables = changes.findAll { it.type == 'aws_dynamodb_table' }
  def destroy      = dynamoTables.any { 'delete' in it.change.actions }
  def replace      = dynamoTables.any { it.change.actions == ['delete', 'create'] }
  def schemaChange = dynamoTables.any { c ->
    def before = c.change.before ?: [:]
    def after  = c.change.after  ?: [:]
    before.hash_key != after.hash_key || before.range_key != after.range_key
  }
  return [
    dynamoDestroy:      destroy,
    dynamoSchemaChange: schemaChange || replace,
    replaceCount:       changes.count { it.change.actions == ['delete', 'create'] },
    destroyCount:       changes.count { 'delete' in it.change.actions },
    criticalResources:  dynamoTables.collect { it.address }
  ]
}
```

---

## 🔐 Secrets management

| Loại | Cách lưu | Scope |
|---|---|---|
| AWS credentials | **OIDC** (Jenkins → STS AssumeRoleWithWebIdentity) | Per env (uat-runner, staging-runner, prod-runner) |
| GitHub token | Jenkins Credential Store, type `Username + PAT` | Folder `videopress/` |
| Teams webhook | Jenkins Credential Store, type `Secret text` | Folder `videopress/` |
| Slack webhook | Jenkins Credential Store, type `Secret text` | Folder `videopress/` |
| Sonar token (nếu có) | Jenkins Credential Store, type `Secret text` | Folder `videopress/` |

> ⚠️ **TUYỆT ĐỐI KHÔNG** hardcode webhook URL hay role ARN trong code Groovy. Mọi giá trị đến qua `env.*` hoặc parameter `config`.

Đọc đầy đủ: [`docs/secrets-management.md`](docs/secrets-management.md).

---

## 🔄 Versioning & release

Tuân thủ **Semantic Versioning** (MAJOR.MINOR.PATCH):

- **MAJOR** — breaking change của DSL signature (xoá tham số, đổi kiểu trả về). Consumer phải sửa Jenkinsfile.
- **MINOR** — thêm tham số optional, thêm function mới. Consumer không cần sửa.
- **PATCH** — bug fix, refactor nội bộ, không đổi API.

Tag convention: `vMAJOR.MINOR.PATCH` (ví dụ `v1.2.0`).

```bash
# Bump version
git tag -a v1.2.0 -m "feat(deploy): add prod cooldown gate"
git push origin v1.2.0
```

Đọc thêm: [`VERSIONING.md`](VERSIONING.md), [`CHANGELOG.md`](CHANGELOG.md).

---

## 📝 Add new pipeline DSL — step-by-step

1. **Tạo file** `vars/myNewPipeline.groovy` — function `def call(Map config) { ... }`.
2. **Validate config** ở đầu function:
   ```groovy
   assert config.foo : "myNewPipeline: missing required param 'foo'"
   ```
3. **Tách logic phức tạp** thành class trong `src/com/videopress/...`.
4. **Viết Spock spec** trong `src/test/groovy/com/videopress/...` — coverage ≥ 80%.
5. **Tạo Jenkinsfile mẫu** trong `pipelines/Jenkinsfile.my-new.sample`.
6. **Update bảng** ở mục "Pipeline DSL functions" trong README này.
7. **Update CHANGELOG.md** section `[Unreleased]`.
8. **Mở PR** — CI chạy `./gradlew check`. Cần ≥ 1 approval từ `@videopress-org/sre-leads`.

---

## 🤝 Contributing

### PR convention

- Branch: `feat/<short-desc>`, `fix/<short-desc>`, `docs/<short-desc>`.
- Commit: Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`).
- PR title: `<type>(<scope>): <summary>` — ví dụ `feat(deploy): add prod cooldown gate`.
- PR description theo `.github/pull_request_template.md`.

### Test bắt buộc

- Mỗi class mới có Spock spec tương ứng.
- Coverage ≥ **80%** (kiểm tra qua JaCoCo report).
- CodeNarc lint pass — không có `WARNING` level mới.

### Review

- Code change ở `vars/` cần ≥ 1 approval từ `@videopress-org/sre-leads`.
- Code change ở `src/com/videopress/aws/` cần ≥ 1 approval từ `@videopress-org/security-team`.

---

## 👥 Owner

- **Team**: SRE / DevOps
- **Slack**: `#videopress-sre`
- **Teams channel**: `VideoPress / SRE`
- **On-call rotation**: PagerDuty service `videopress-platform`
- **Email**: `sre@videopress.example.com`

---

## 🔗 Liên kết các repo consumer

| Repo | Mục đích | Pipeline gọi |
|---|---|---|
| [videopress-backend](https://github.com/videopress/videopress-backend) | Code Python Lambda | `pythonLambdaPipeline` |
| [videopress-infrastructure](https://github.com/videopress/videopress-infrastructure) | Terraform IaC (uat/staging/prod) | `terraformPlanPipeline`, `terraformDeployPipeline`, `terraformRollbackPipeline`, `smokeTestPipeline` |
| [videopress-platform-docs](https://github.com/videopress/videopress-platform-docs) (optional) | ADR, diagram, runbook | _none — pure docs_ |

---

> 📚 Xem thêm: [`docs/pipeline-design.md`](docs/pipeline-design.md) · [`docs/secrets-management.md`](docs/secrets-management.md) · [`docs/on-call-runbook.md`](docs/on-call-runbook.md)
