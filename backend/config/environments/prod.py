"""
프로덕션 환경 설정
"""
CONFIG = {
    # 로깅
    'LOG_LEVEL': 'WARNING',
    'ENABLE_DETAILED_LOGS': False,
    
    # AWS 설정
    'AWS_REGION': 'ap-northeast-2',  # 서울 리전
    
    # Bedrock 설정 - Claude 4.1 Opus (프로덕션)
    'BEDROCK_MODEL_ID': 'us.anthropic.claude-opus-4-1-20250805-v1:0',
    'BEDROCK_MAX_TOKENS': 4096,
    'BEDROCK_TEMPERATURE': 0.5,  # 프로덕션은 더 일관된 응답
    'BEDROCK_TIMEOUT': 180,
    
    # Guardrail 설정
    'GUARDRAIL_ENABLED': True,
    'GUARDRAIL_ID': 'prod-guardrail',
    'GUARDRAIL_VERSION': 'LATEST',
    
    # DynamoDB 설정
    'DYNAMODB_READ_CAPACITY': 20,
    'DYNAMODB_WRITE_CAPACITY': 20,
    'DYNAMODB_BILLING_MODE': 'PAY_PER_REQUEST',
    'DYNAMODB_POINT_IN_TIME_RECOVERY': True,
    'DYNAMODB_ENCRYPTION': 'AWS_OWNED_CMK',
    
    # API 설정
    'API_RATE_LIMIT': 1000,
    'API_BURST_LIMIT': 2000,
    'API_THROTTLE_ENABLED': True,
    
    # WebSocket 설정
    'WEBSOCKET_IDLE_TIMEOUT': 1800,  # 30분
    'WEBSOCKET_MAX_CONNECTIONS': 1000,
    
    # 캐싱 설정
    'CACHE_TTL': 1800,  # 30분
    'ENABLE_CACHE': True,
    
    # 토큰 제한
    'MAX_INPUT_TOKENS': 4000,
    'MAX_OUTPUT_TOKENS': 4000,
    'MAX_CONVERSATION_LENGTH': 50,
    
    # 디버그 설정
    'DEBUG': False,
    'ENABLE_XRAY': True,
    'ENABLE_PROFILING': True,
    
    # CORS 설정
    'CORS_ORIGINS': [
        'https://nexus.example.com',
        'https://www.nexus.example.com',
        'https://admin.nexus.example.com'
    ],
    'CORS_CREDENTIALS': True,
    
    # 보안 설정
    'ENABLE_API_KEY': True,
    'ENABLE_REQUEST_SIGNING': True,
    'ENABLE_ENCRYPTION_AT_REST': True,
    
    # 모니터링
    'CLOUDWATCH_METRICS_ENABLED': True,
    'CLOUDWATCH_LOGS_RETENTION': 30,  # days
    
    # 기능 플래그
    'FEATURES': {
        'ENABLE_STREAMING': True,
        'ENABLE_FILE_UPLOAD': True,
        'ENABLE_USAGE_TRACKING': True,
        'ENABLE_CONVERSATION_HISTORY': True,
        'ENABLE_PROMPT_MANAGEMENT': True,
    },
    
    # 백업 설정
    'BACKUP': {
        'ENABLED': True,
        'RETENTION_DAYS': 7,
        'SCHEDULE': 'cron(0 3 * * ? *)'  # 매일 새벽 3시
    }
}