# `upload_lambda`

Lambda quản lý flow upload video lên S3 trước khi nén.

## 📡 Endpoints

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/uploads/request` | POST | Bearer | Generate presigned URL S3 PUT, trả `job_id` |
| `/api/v1/uploads/confirm` | POST | Bearer | Client báo PUT xong → enqueue SQS để compression |

## 🔄 Flow upload

```
Client                  upload_lambda          S3              compression queue
  │                          │                  │                       │
  ├──POST /uploads/request──>│                  │                       │
  │<──{job_id, upload_url}───┤                  │                       │
  │                          │                  │                       │
  ├──PUT video.mp4 (presigned URL)─────────────>│                       │
  │                          │                  │                       │
  ├──POST /uploads/confirm──>│                  │                       │
  │                          ├──head_object────>│                       │
  │                          ├──send_message──────────────────────────>│
  │<──{job_id, status:QUEUED}┤                  │                       │
```

## 📥 Ví dụ event (request)

```json
{
  "httpMethod": "POST",
  "path": "/api/v1/uploads/request",
  "body": "{\"file_name\":\"video.mp4\",\"content_type\":\"video/mp4\"}",
  "headers": { "Authorization": "Bearer eyJ..." }
}
```

## 📤 Ví dụ response

```json
{
  "statusCode": 200,
  "body": "{\"job_id\":\"01HXYZ...\",\"upload_url\":\"https://s3.../...\",\"expires_in\":900}"
}
```

## 🌍 Environment variables

| Var | Mô tả |
|---|---|
| `UPLOAD_BUCKET_NAME` | S3 bucket nhận file gốc |
| `COMPRESSION_QUEUE_URL` | SQS queue URL trigger compression_lambda |
| `JOB_TABLE_NAME` | DynamoDB table track job state |
| `AWS_REGION` | Region |

## 🔐 IAM permissions

- `s3:PutObject`, `s3:HeadObject` trên `UPLOAD_BUCKET_NAME` (KHÔNG cần `s3:GetObject`)
- `sqs:SendMessage` trên `COMPRESSION_QUEUE_URL`
- `dynamodb:PutItem`, `dynamodb:UpdateItem` trên `JOB_TABLE_NAME`

## 🧪 Test local

```bash
pytest upload_lambda/tests/ -v --cov=upload_lambda
```
