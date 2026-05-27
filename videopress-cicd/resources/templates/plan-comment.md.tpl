## 🤖 Terraform Plan Review

{{PLAN_SUMMARY}}

### 💰 Cost diff (vs base branch)

```
{{COST_DIFF}}
```

### 🔥 Critical resources bị thay đổi

{{CRITICAL_LIST}}

---

> Pipeline tự động chặn merge nếu phát hiện **DynamoDB schema change** hoặc **destroy**.
> Nếu bạn cần xử lý migration data, mở PR riêng có RFC link + 2 reviewer (1 từ `@videopress-org/security-team`).
>
> 🔗 [Build URL]({{BUILD_URL}}) · 📚 [DynamoDB safety doc](docs/pipeline-design.md#dynamodb-safety-enforcement)
