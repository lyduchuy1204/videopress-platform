# `authentication_lambda`

Lambda xử lý **xác thực user** cho VideoPress Platform. Gắn vào API Gateway path `/api/v1/auth/*`.

## 📡 Endpoints

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/auth/login` | POST | None | Đăng nhập email + password, trả Cognito tokens |
| `/api/v1/auth/otp_verify` | POST | None | Verify OTP 6 chữ số (MFA / passwordless) |
| `/api/v1/auth/refresh_token` | POST | None | Đổi refresh token thành access token mới |
| `/api/v1/auth/logout` | POST | Bearer | Revoke token hiện tại (Cognito GlobalSignOut) |

## 📥 Ví dụ event (login)

```json
{
  "httpMethod": "POST",
  "path": "/api/v1/auth/login",
  "headers": { "Content-Type": "application/json" },
  "body": "{\"email\":\"alice@example.com\",\"password\":\"hunter2\"}",
  "requestContext": { "requestId": "abc-123" }
}
```

## 📤 Ví dụ response (login success)

```json
{
  "statusCode": 200,
  "headers": { "Content-Type": "application/json" },
  "body": "{\"access_token\":\"eyJ...\",\"refresh_token\":\"eyJ...\",\"expires_in\":3600,\"token_type\":\"Bearer\"}"
}
```

## 📂 Cấu trúc

```
authentication_lambda/
├── app.py                            ← entry: lambda_handler routes theo path
├── handlers/
│   ├── login.py
│   ├── otp_verify.py
│   ├── refresh_token.py
│   └── logout.py
├── services/
│   └── cognito_service.py            ← wrapper boto3 cognito-idp
├── tests/
│   ├── conftest.py
│   └── test_login.py
├── requirements.txt
└── README.md
```

## 🌍 Environment variables (Terraform inject)

| Var | Mô tả |
|---|---|
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID (vd: `us-east-1_XXXXXX`) |
| `COGNITO_CLIENT_ID` | App Client ID |
| `AWS_REGION` | Region triển khai |
| `OTP_TABLE_NAME` | DynamoDB table lưu OTP |

## 🔐 IAM permissions cần thiết

- `cognito-idp:InitiateAuth`
- `cognito-idp:RespondToAuthChallenge`
- `cognito-idp:GlobalSignOut`
- `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:UpdateItem` trên table OTP
- `secretsmanager:GetSecretValue` cho secret `videopress/jwt-signing-key`
- `logs:CreateLogStream`, `logs:PutLogEvents` (mặc định Lambda)

## 🧪 Test local

```bash
pytest authentication_lambda/tests/ -v --cov=authentication_lambda
```
