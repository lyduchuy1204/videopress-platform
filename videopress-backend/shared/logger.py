"""AWS Lambda Powertools logger wrapper - dùng chung cho mọi lambda.

Mọi lambda nên import từ đây thay vì khởi tạo Logger riêng, để đảm bảo:
- Service name nhất quán: "videopress-backend"
- Log format JSON chuẩn (Powertools tự động structured logging)
- Correlation ID tự động propagate qua API Gateway request ID
"""

from aws_lambda_powertools import Logger

# Service name dùng chung. Mỗi lambda có thể override service riêng nếu cần
# bằng cách: logger = Logger(service="authentication_lambda")
logger = Logger(service="videopress-backend")
