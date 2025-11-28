"""
스테이징 환경 설정
"""
CONFIG = {
    # 로깅
    'LOG_LEVEL': 'INFO',
    'ENABLE_DETAILED_LOGS': True,
    
    # AWS 설정
    'AWS_REGION': 'us-east-1',
    
    # Bedrock 설정 - Claude 4.1 Opus
    'BEDROCK_MODEL_ID': 'us.anthropic.claude-opus-4-1-20250805-v1:0',
    'BEDROCK_MAX_TOKENS': 4096,
    'BEDROCK_TEMPERATURE': 0.7,
    'BEDROCK_TIMEOUT': 120,
    
    # Guardrail 설정
    'GUARDRAIL_ENABLED': True,
    'GUARDRAIL_ID': 'staging-guardrail',
    'GUARDRAIL_VERSION': '1',
    
    # DynamoDB 설정
    'DYNAMODB_READ_CAPACITY': 10,
    'DYNAMODB_WRITE_CAPACITY': 10,
    'DYNAMODB_BILLING_MODE': 'PAY_PER_REQUEST',
    
    # API 설정
    'API_RATE_LIMIT': 500,
    'API_BURST_LIMIT': 1000,
    'API_THROTTLE_ENABLED': True,
    
    # WebSocket 설정
    'WEBSOCKET_IDLE_TIMEOUT': 900,  # 15분
    'WEBSOCKET_MAX_CONNECTIONS': 500,
    
    # 캐싱 설정
    'CACHE_TTL': 600,  # 10분
    'ENABLE_CACHE': True,
    
    # 토큰 제한
    'MAX_INPUT_TOKENS': 3000,
    'MAX_OUTPUT_TOKENS': 3000,
    'MAX_CONVERSATION_LENGTH': 30,
    
    # 디버그 설정
    'DEBUG': False,
    'ENABLE_XRAY': True,
    'ENABLE_PROFILING': False,
    
    # CORS 설정
    'CORS_ORIGINS': [
        'https://staging.nexus.example.com',
        'https://staging-admin.nexus.example.com'
    ],
    'CORS_CREDENTIALS': True,
    
    # 기능 플래그
    'FEATURES': {
        'ENABLE_STREAMING': True,
        'ENABLE_FILE_UPLOAD': True,
        'ENABLE_USAGE_TRACKING': True,
        'ENABLE_CONVERSATION_HISTORY': True,
        'ENABLE_PROMPT_MANAGEMENT': True,
    }
}