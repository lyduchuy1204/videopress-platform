# `notification_lambda`

Lambda quản lý notification cho user (in-app + email transactional qua SES).

## 📡 Endpoints

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/notifications` | GET | Bearer | List notification của user, paginate cursor-based |
| `/api/v1/notifications/mark_read` | POST | Bearer | Đánh dấu đã đọc 1 hoặc nhiều notif |
| `/api/v1/notifications/push_email` | POST | Internal | Trigger gửi email qua SES (gọi từ lambda khác) |

## 📥 Ví dụ event (list)

```json
{
  "httpMethod": "GET",
  "path": "/api/v1/notifications",
  "queryStringParameters": { "limit": "20", "cursor": "abc" },
  "headers": { "Authorization": "Bearer eyJ..." }
}
```

## 📤 Ví dụ response

```json
{
  "statusCode": 200,
  "body": "{\"items\":[{\"id\":\"notif-1\",\"type\":\"JOB_COMPLETED\",\"read\":false}],\"next_cursor\":null}"
}
```

## 📂 Cấu trúc

```
notification_lambda/
├── app.py
├── handlers/
│   ├── list_notifications.py
│   ├── mark_read.py
│   └── push_email.py
├── services/
│   ├── ses_service.py
│   └── notification_repository.py
├── tests/
├── requirements.txt
└── README.md
```

## 🌍 Environment variables

| Var | Mô tả |
|---|---|
| `NOTIFICATION_TABLE_NAME` | DynamoDB table name |
| `SES_FROM_ADDRESS` | Địa chỉ "From:" verified trong SES |
| `AWS_REGION` | Region |

## 🔐 IAM permissions

- `dynamodb:Query`, `dynamodb:UpdateItem`, `dynamodb:BatchWriteItem` trên notification table
- `ses:SendEmail`, `ses:SendTemplatedEmail`
- `secretsmanager:GetSecretValue` (nếu cần SMTP credential)
- `logs:*` (mặc định)

## 🧪 Test local

```bash
pytest notification_lambda/tests/ -v --cov=notification_lambda
```
