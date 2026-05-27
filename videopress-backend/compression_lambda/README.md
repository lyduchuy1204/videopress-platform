# `compression_lambda`

Lambda **SQS-triggered worker** — KHÔNG có HTTP endpoint. Nhận message từ SQS queue, gọi MediaConvert tạo job nén video.

## 📡 Trigger

| Source | Type | Description |
|---|---|---|
| SQS queue `videopress-compression-queue` | Event source mapping | Batch up to 10 messages, partial batch response |

## 📥 Ví dụ event (SQS)

```json
{
  "Records": [
    {
      "messageId": "msg-uuid",
      "body": "{\"job_id\":\"01HXYZ...\",\"s3_key\":\"raw/u-1/video.mp4\",\"user_id\":\"u-1\",\"preset\":\"h264-720p\"}",
      "attributes": { "ApproximateReceiveCount": "1" },
      "eventSource": "aws:sqs"
    }
  ]
}
```

## 📤 Response (SQS partial batch)

```json
{
  "batchItemFailures": [
    { "itemIdentifier": "msg-uuid-failed" }
  ]
}
```

> Lambda KHÔNG return HTTP shape. Chỉ liệt kê message thất bại để SQS retry.

## 📂 Cấu trúc

```
compression_lambda/
├── app.py                            ← entry: SQS batch handler
├── handlers/
│   └── process_compression_job.py
├── services/
│   └── mediaconvert_service.py
├── tests/
├── requirements.txt
└── README.md
```

## 🌍 Environment variables

| Var | Mô tả |
|---|---|
| `MEDIACONVERT_QUEUE_ARN` | MediaConvert queue ARN |
| `MEDIACONVERT_ROLE_ARN` | IAM role MediaConvert assume để đọc S3 input + ghi S3 output |
| `JOB_TABLE_NAME` | DynamoDB table track job |
| `OUTPUT_BUCKET_NAME` | S3 bucket nhận file đã nén |
| `INPUT_BUCKET_NAME` | S3 bucket chứa file gốc |

## 🔐 IAM permissions

- `mediaconvert:CreateJob`, `mediaconvert:GetJob`
- `iam:PassRole` (cho MediaConvert role)
- `s3:GetObject` trên `INPUT_BUCKET_NAME`
- `s3:PutObject` trên `OUTPUT_BUCKET_NAME`
- `dynamodb:UpdateItem` trên `JOB_TABLE_NAME`
- `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` (cho event source mapping)

## ⚠️ Retry & DLQ

- Queue có `maxReceiveCount=3` rồi vào DLQ `videopress-compression-dlq`.
- Lambda return `batchItemFailures` để chỉ retry message fail (không retry cả batch).

## 🧪 Test local

```bash
pytest compression_lambda/tests/ -v --cov=compression_lambda
```
