"""
환경별 설정 모듈
"""
import os
from typing import Dict, Any

def get_environment_config() -> Dict[str, Any]:
    """현재 환경에 맞는 설정 로드"""
    environment = os.environ.get('ENVIRONMENT', 'dev')
    
    if environment == 'dev':
        from .dev import CONFIG
    elif environment == 'staging':
        from .staging import CONFIG
    elif environment == 'prod':
        from .prod import CONFIG
    else:
        # 기본값은 dev
        from .dev import CONFIG
    
    return CONFIG