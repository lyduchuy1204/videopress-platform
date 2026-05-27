# `job_status_lambda`

Lambda query trạng thái compression job theo `job_id`.

## 📡 Endpoints

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/jobs/{id}` | GET | Bearer | Lấy status + progress của 1 job, kèm output URL nếu xong |

## 📥 Ví dụ event

```json
{
  "httpMethod": "GET",
  "path": "/api/v1/jobs/01HXYZ",
  "pathParameters": { "id": "01HXYZ" },
  "headers": { "Authorization": "Bearer eyJ..." }
}
```

## 📤 Ví dụ response

```json
{
  "statusCode": 200,
  "body": "{\"id\":\"01HXYZ\",\"status\":\"PROCESSING\",\"progress\":42,\"output_url\":null,\"created_at\":\"2026-01-01T00:00:00Z\"}"
}
```

Status values: `PENDING`, `PROCESSING`, `COMPLETED`, `FAILED`.

## 📂 Cấu trúc

```
job_status_lambda/
├── app.py
├── handlers/
│   └── get_job_status.py
├── services/
│   └── job_repository.py
├── tests/
├── requirements.txt
└── README.md
```

## 🌍 Environment variables

| Var | Mô tả |
|---|---|
| `JOB_TABLE_NAME` | DynamoDB table |
| `OUTPUT_BUCKET_NAME` | Bucket chứa file output (để gen presigned GET URL) |
| `AWS_REGION` | Region |

## 🔐 IAM permissions

- `dynamodb:GetItem` trên `JOB_TABLE_NAME`
- `s3:GetObject` trên `OUTPUT_BUCKET_NAME` (để generate presigned URL)
- `logs:*` (mặc định)

## 🔒 Security note

Handler **PHẢI verify ownership** — match `job.user_id` với `sub` trong JWT. Nếu không match, trả 404 (không phải 403, để tránh leak existence của job ID).

## 🧪 Test local

```bash
pytest job_status_lambda/tests/ -v --cov=job_status_lambda
```
