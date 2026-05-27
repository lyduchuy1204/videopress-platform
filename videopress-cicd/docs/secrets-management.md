# Secrets Management

> Cách quản lý secrets cho Jenkins Shared Library `videopress-cicd`.

---

## 1. Phân loại secret

| Loại | Storage | Scope | Rotation |
|---|---|---|---|
| AWS credentials | **OIDC** (STS AssumeRoleWithWebIdentity) | Per env | Token 1h, role policy review hàng quý |
| GitHub PAT (PR comment) | Jenkins Credential Store, type `Secret text` | Folder `videopress/` | 90 ngày |
| Teams webhook | Jenkins Credential Store, type `Secret text` | Folder `videopress/` | Khi rò rỉ |
| Slack webhook | Jenkins Credential Store, type `Secret text` | Folder `videopress/` | Khi rò rỉ |
| Sonar token | Jenkins Credential Store, type `Secret text` | Folder `videopress/` | 180 ngày |
| Infracost API key | Jenkins Credential Store, type `Secret text` | Folder `videopress/` | 180 ngày |
| Cognito App Client Secret | **AWS Secrets Manager** | Per env | Auto-rotate qua Lambda |
| 3rd party API key | **AWS Secrets Manager** | Per env | Khi đổi vendor |

> 💡 **KHÔNG** lưu API key của 3rd party qua Terraform variable — giá trị plain text rò vào tfstate. Luôn ghi vào Secrets Manager rồi Lambda đọc qua role.

---

## 2. Jenkins Credential Store — folder-level scope

### Cấu trúc folder Jenkins

```
Jenkins root /
├── videopress/                          ← Folder cho VideoPress Platform
│   ├── credentials/                     ← Credentials scope folder này
│   │   ├── github-pat-pr-comment        (Secret text)
│   │   ├── teams-webhook-deploy         (Secret text)
│   │   ├── teams-webhook-incident       (Secret text)
│   │   ├── slack-webhook-sre            (Secret text)
│   │   ├── infracost-api-key            (Secret text)
│   │   └── github-readonly-pat          (Username + Password)
│   ├── videopress-backend/              ← Sub-folder cho repo backend
│   ├── videopress-infrastructure/       ← Sub-folder cho repo IaC
│   └── videopress-cicd/                 ← Sub-folder cho repo này
└── (folder khác)
```

### Vì sao dùng folder scope thay vì global?

- **Blast radius nhỏ**: Compromise 1 job không lộ secrets của project khác.
- **ACL rõ**: Chỉ user có role `videopress-developer` đọc được.
- **Audit dễ**: Search log Jenkins theo folder name.

### Cấu hình ACL

```
Folder videopress/ → Configure → Properties → Authorization
  Strategy: Project-based Matrix Authorization
  Roles:
    videopress-developer     → Read, Build, Cancel
    videopress-deployer      → + ConfigureWorkspace
    videopress-sre-oncall    → + Replay, Rebuild
    videopress-admin         → All
```

---

## 3. AWS credentials qua OIDC

### Vì sao OIDC > access key tĩnh?

| Access key tĩnh | OIDC |
|---|---|
| Tồn tại lâu dài, có thể bị leak qua log | Token 1h, expire tự động |
| Phải rotate thủ công | Mỗi build sinh token mới |
| Phải lưu ở Jenkins Credential | Không cần lưu — lấy qua AssumeRoleWithWebIdentity |
| Bị stolen → attacker chạy lúc nào cũng được | Stolen token chỉ valid trong 1h, nếu out role session đã apply |

### Cấu hình

1. **Trên AWS**: tạo OIDC provider trỏ tới Jenkins URL → tạo IAM Role với `Trust policy` cho `sub: jenkins-${env}-runner`.
2. **Trên Jenkins**: cài plugin `aws-credentials` + `pipeline-aws-plugin`.
3. **Pipeline**: gọi `AssumeRole.withOidc(roleArn) { ... }` — class này wrap STS call.

### Trust policy mẫu (Terraform)

```hcl
resource "aws_iam_role" "jenkins_uat_runner" {
  name = "jenkins-uat-runner"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.jenkins.arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.jenkins.url, "https://", "")}:sub" = "repo:videopress/*:env:uat"
        }
      }
    }]
  })
}
```

---

## 4. Cảnh báo về `withCredentials` block

### ❌ ĐỪNG làm thế này

```groovy
// SAI — credential leak vào log nếu pipeline echo env.
withCredentials([string(credentialsId: 'foo', variable: 'TOKEN')]) {
  sh "echo TOKEN=${TOKEN}"     // ❌ in vào log
  sh 'curl -H "auth: $TOKEN" ...'  // ❌ Jenkins set +x cũng vẫn log lệnh nếu xset -x bật
}
```

### ✅ Đúng

```groovy
withCredentials([string(credentialsId: 'foo', variable: 'TOKEN')]) {
  try {
    sh '''
      set +x   # tắt log lệnh
      curl -H "auth: $TOKEN" ...
    '''
  } finally {
    sh 'unset TOKEN || true'   # defense-in-depth
  }
}
```

> Mọi DSL function trong repo này đã enforce pattern `try/finally` để cleanup.

---

## 5. Rotation policy

| Secret | Tần suất | Chủ trì |
|---|---|---|
| GitHub PAT | 90 ngày | DevOps |
| Sonar / Infracost API key | 180 ngày | DevOps |
| Webhook (Teams/Slack) | Theo nhu cầu (re-create channel, leak) | SRE |
| AWS OIDC role policy | Quý | Security |
| Cognito secret | Auto-rotate (AWS Secrets Manager scheduler) | Auto |

### Quy trình rotate GitHub PAT

1. Tạo PAT mới ở GitHub (scope: `repo`, expire 90 ngày).
2. Vào Jenkins → Folder `videopress/` → Credentials → Edit `github-pat-pr-comment` → paste token mới.
3. Trigger lại 1 PR plan để verify hoạt động.
4. Revoke PAT cũ trên GitHub.

---

## 6. Incident response — leak secret

1. **Revoke ngay** ở provider (GitHub, AWS).
2. Rotate credential mới ở Jenkins.
3. Audit log: `git log --all -S "<token>"` xem đã từng commit chưa.
4. Nếu commit rồi: rewrite history (`git filter-repo`) + force push + thông báo team.
5. Hậu kỳ: post-mortem, cập nhật scanning rule (gitleaks pre-commit).
