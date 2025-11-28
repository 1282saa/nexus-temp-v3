"""
중앙 설정 관리 시스템
환경변수 기반으로 모든 설정을 동적으로 관리
하드코딩 제거를 위한 설정 파일
"""
import os
from typing import Dict, Any, Optional

class Settings:
    """애플리케이션 설정 관리 클래스"""
    
    def __init__(self):
        # 서비스 기본 정보
        self.SERVICE_NAME = os.environ.get('SERVICE_NAME', 'nexus')
        self.ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
        self.STACK_SUFFIX = os.environ.get('STACK_SUFFIX', 'dev')
        
        # AWS 설정
        self.AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')
        self.AWS_ACCOUNT_ID = os.environ.get('AWS_ACCOUNT_ID', '')
        
        # 테이블 이름 패턴 (하드코딩 제거)
        self.TABLE_PREFIX = f"{self.SERVICE_NAME}-"
        self.TABLE_SUFFIX = f"-{self.STACK_SUFFIX}"
        
        # API Gateway
        self.API_STAGE = os.environ.get('API_STAGE', 'prod')
        self.REST_API_ID = os.environ.get('REST_API_ID', '')
        self.WEBSOCKET_API_ID = os.environ.get('WEBSOCKET_API_ID', '')
        
        # Bedrock 설정
        self.BEDROCK_MODEL_ID = os.environ.get(
            'BEDROCK_MODEL_ID', 
            'anthropic.claude-3-sonnet-20240229-v1:0'
        )
        
        # 로깅
        self.LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
        
    def get_table_name(self, table_type: str) -> str:
        """
        테이블 이름을 동적으로 생성
        예: SERVICE_NAME=myapp, STACK_SUFFIX=prod
        결과: myapp-conversations-prod
        """
        # 환경변수로 직접 지정된 경우 우선 사용
        env_key = f"{table_type.upper()}_TABLE"
        if env_value := os.environ.get(env_key):
            return env_value
        
        # 아니면 패턴으로 생성
        table_names = {
            'conversations': 'conversations',
            'prompts': 'prompts',
            'usage': 'usage',
            'websocket': 'websocket-connections',
            'websocket_connections': 'websocket-connections',
            'files': 'files',
            'messages': 'messages'
        }
        
        base_name = table_names.get(table_type, table_type)
        return f"{self.TABLE_PREFIX}{base_name}{self.TABLE_SUFFIX}"
    
    def get_lambda_name(self, function_type: str) -> str:
        """
        Lambda 함수 이름을 동적으로 생성
        """
        lambda_names = {
            'conversation': 'conversation-api',
            'prompt': 'prompt-crud',
            'usage': 'usage-handler',
            'connect': 'websocket-connect',
            'disconnect': 'websocket-disconnect',
            'message': 'websocket-message'
        }
        
        base_name = lambda_names.get(function_type, function_type)
        return f"{self.TABLE_PREFIX}{base_name}{self.TABLE_SUFFIX}"
    
    def get_api_endpoint(self, api_type: str = 'rest') -> str:
        """API 엔드포인트 URL 생성"""
        if api_type == 'rest':
            if self.REST_API_ID:
                return f"https://{self.REST_API_ID}.execute-api.{self.AWS_REGION}.amazonaws.com/{self.API_STAGE}"
        elif api_type == 'websocket':
            if self.WEBSOCKET_API_ID:
                return f"wss://{self.WEBSOCKET_API_ID}.execute-api.{self.AWS_REGION}.amazonaws.com/{self.API_STAGE}"
        return ""
    
    def to_dict(self) -> Dict[str, Any]:
        """설정을 딕셔너리로 변환"""
        return {
            'SERVICE_NAME': self.SERVICE_NAME,
            'ENVIRONMENT': self.ENVIRONMENT,
            'AWS_REGION': self.AWS_REGION,
            'TABLE_PREFIX': self.TABLE_PREFIX,
            'TABLE_SUFFIX': self.TABLE_SUFFIX,
            'LOG_LEVEL': self.LOG_LEVEL,
            'BEDROCK_MODEL_ID': self.BEDROCK_MODEL_ID
        }
    
    def validate(self) -> bool:
        """필수 설정 검증"""
        required = ['SERVICE_NAME', 'ENVIRONMENT', 'AWS_REGION']
        for field in required:
            if not getattr(self, field):
                print(f"Warning: {field} is not set")
                return False
        return True


# 싱글톤 인스턴스
settings = Settings()

# 하위 호환성을 위한 변수들
SERVICE_NAME = settings.SERVICE_NAME
ENVIRONMENT = settings.ENVIRONMENT
AWS_REGION = settings.AWS_REGION
STACK_SUFFIX = settings.STACK_SUFFIX


def get_config() -> Settings:
    """설정 객체 반환"""
    return settings