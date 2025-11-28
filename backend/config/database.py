"""
데이터베이스 설정 - 하드코딩 제거 버전
settings.py를 사용하여 동적으로 테이블 이름 생성
"""
import os
from typing import Dict, Any
from .settings import settings

# DynamoDB 테이블 설정 (동적 생성)
TABLES = {
    'conversations': {
        'name': settings.get_table_name('conversations'),
        'partition_key': 'conversationId',
        'indexes': {
            'userId-createdAt-index': {
                'partition_key': 'userId',
                'sort_key': 'createdAt'
            }
        }
    },
    'prompts': {
        'name': settings.get_table_name('prompts'),
        'partition_key': 'promptId',
        'indexes': {
            'userId-index': {
                'partition_key': 'userId',
                'sort_key': 'updatedAt'
            }
        }
    },
    'usage': {
        'name': settings.get_table_name('usage'),
        'partition_key': 'userId',
        'sort_key': 'usageDate#engineType',
        'indexes': {
            'date-index': {
                'partition_key': 'usageDate',
                'sort_key': 'userId'
            }
        }
    },
    'websocket_connections': {
        'name': settings.get_table_name('websocket_connections'),
        'partition_key': 'connectionId'
    },
    'files': {
        'name': settings.get_table_name('files'),
        'partition_key': 'promptId',
        'sort_key': 'fileId'
    },
    'messages': {
        'name': settings.get_table_name('messages'),
        'partition_key': 'messageId',
        'sort_key': 'conversationId'
    }
}

# AWS 리전 설정
AWS_REGION = settings.AWS_REGION

# DynamoDB 설정
DYNAMODB_CONFIG = {
    'region_name': AWS_REGION,
    'max_retries': 3,
    'timeout': 10
}

def get_table_name(table_type: str) -> str:
    """
    테이블 이름 조회
    settings.py의 동적 생성 로직 사용
    """
    # TABLES에 정의된 경우
    if table_type in TABLES:
        return TABLES[table_type]['name']
    
    # 아니면 settings에서 동적 생성
    return settings.get_table_name(table_type)

def get_table_config(table_type: str) -> Dict[str, Any]:
    """테이블 설정 조회"""
    if table_type not in TABLES:
        # 기본 설정 반환
        return {
            'name': settings.get_table_name(table_type),
            'partition_key': 'id'
        }
    return TABLES[table_type]

def get_all_table_names() -> Dict[str, str]:
    """모든 테이블 이름 반환 (디버깅용)"""
    return {
        table_type: config['name'] 
        for table_type, config in TABLES.items()
    }

# 환경 정보 출력 (디버깅용)
if __name__ == "__main__":
    print("=== Database Configuration ===")
    print(f"Service: {settings.SERVICE_NAME}")
    print(f"Environment: {settings.ENVIRONMENT}")
    print(f"Region: {AWS_REGION}")
    print("\nTable Names:")
    for table_type, name in get_all_table_names().items():
        print(f"  {table_type}: {name}")