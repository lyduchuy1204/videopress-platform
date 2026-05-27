# Module — `lambda-layer`

> 1 Lambda layer version từ S3 source. Layer này chứa shared dependency (`aws-lambda-powertools`, `pydantic`, `boto3` pinned) cho 5 Lambda dùng chung.

## 📋 Inputs

| Tên | Type | Default | Mô tả |
|---|---|---|---|
| `layer_name` | `string` | — | Tên layer (vd `videopress-common-uat`). |
| `description` | `string` | `""` | Mô tả layer. |
| `s3_bucket` | `string` | — | Bucket chứa zip layer. |
| `s3_key` | `string` | — | Object key zip. |
| `compatible_runtimes` | `list(string)` | `["python3.11"]` | Runtime tương thích. |
| `compatible_architectures` | `list(string)` | `["x86_64"]` | Architecture. |
| `tags` | `map(string)` | — | Tag chuẩn. |

## 📤 Outputs

| Tên | Mô tả |
|---|---|
| `layer_arn` | ARN với version (gắn vào Lambda). |
| `layer_version` | Số version layer. |

## 💡 Example usage

```hcl
module "lambda_layer" {
  source = "../../modules/lambda-layer"

  layer_name           = "videopress-common-${var.environment}"
  description          = "Shared deps: powertools + pydantic + boto3"
  s3_bucket            = var.artifact_bucket
  s3_key               = "layer/videopress-common-${var.layer_version}.zip"
  compatible_runtimes  = ["python3.11"]

  tags = local.common_tags
}
```

## 🔗 Dependencies

- S3 bucket artifact — Layer được build từ `videopress-backend/layer/` qua `Jenkinsfile.layer-build` (xem repo `videopress-cicd`).

## 📝 Notes

- Layer tạo **version mới** mỗi khi `s3_key` thay đổi → Lambda tham chiếu phải update ARN (Terraform tự handle).
- Mỗi Lambda gắn tối đa 5 layer.
- Version cũ KHÔNG tự xoá — cần cleanup script ngoài Terraform (giữ 10 version gần nhất).
