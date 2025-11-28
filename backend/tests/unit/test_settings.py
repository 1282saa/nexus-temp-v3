"""
설정 시스템 단위 테스트
"""
import pytest
import os
from unittest.mock import patch

from config.settings import Settings


class TestSettings:
    """Settings 클래스 테스트"""
    
    def test_default_settings(self):
        """기본 설정 테스트"""
        with patch.dict(os.environ, {}, clear=True):
            settings = Settings()
            
            assert settings.SERVICE_NAME == 'nexus'
            assert settings.ENVIRONMENT == 'dev'
            assert settings.STACK_SUFFIX == 'dev'
            assert settings.AWS_REGION == 'us-east-1'
    
    def test_custom_settings(self):
        """커스텀 설정 테스트"""
        with patch.dict(os.environ, {
            'SERVICE_NAME': 'my-service',
            'ENVIRONMENT': 'prod',
            'STACK_SUFFIX': 'prod',
            'AWS_REGION': 'ap-northeast-2'
        }):
            settings = Settings()
            
            assert settings.SERVICE_NAME == 'my-service'
            assert settings.ENVIRONMENT == 'prod'
            assert settings.STACK_SUFFIX == 'prod'
            assert settings.AWS_REGION == 'ap-northeast-2'
    
    def test_table_name_generation(self):
        """테이블 이름 생성 테스트"""
        with patch.dict(os.environ, {
            'SERVICE_NAME': 'test-service',
            'STACK_SUFFIX': 'staging'
        }):
            settings = Settings()
            
            # 표준 테이블 이름
            assert settings.get_table_name('conversations') == 'test-service-conversations-staging'
            assert settings.get_table_name('prompts') == 'test-service-prompts-staging'
            assert settings.get_table_name('usage') == 'test-service-usage-staging'
    
    def test_table_name_override(self):
        """환경변수로 테이블 이름 오버라이드 테스트"""
        with patch.dict(os.environ, {
            'SERVICE_NAME': 'test-service',
            'STACK_SUFFIX': 'dev',
            'CONVERSATIONS_TABLE': 'custom-conversations-table'
        }):
            settings = Settings()
            
            # 오버라이드된 테이블 이름
            assert settings.get_table_name('conversations') == 'custom-conversations-table'
            # 기본 패턴 사용
            assert settings.get_table_name('prompts') == 'test-service-prompts-dev'
    
    def test_lambda_name_generation(self):
        """Lambda 함수 이름 생성 테스트"""
        with patch.dict(os.environ, {
            'SERVICE_NAME': 'my-app',
            'STACK_SUFFIX': 'prod'
        }):
            settings = Settings()
            
            assert settings.get_lambda_name('conversation') == 'my-app-conversation-api-prod'
            assert settings.get_lambda_name('connect') == 'my-app-websocket-connect-prod'
            assert settings.get_lambda_name('message') == 'my-app-websocket-message-prod'
    
    def test_api_endpoint_generation(self):
        """API 엔드포인트 생성 테스트"""
        with patch.dict(os.environ, {
            'AWS_REGION': 'us-west-2',
            'REST_API_ID': 'abc123',
            'WEBSOCKET_API_ID': 'xyz789',
            'API_STAGE': 'v1'
        }):
            settings = Settings()
            
            rest_url = settings.get_api_endpoint('rest')
            assert rest_url == 'https://abc123.execute-api.us-west-2.amazonaws.com/v1'
            
            ws_url = settings.get_api_endpoint('websocket')
            assert ws_url == 'wss://xyz789.execute-api.us-west-2.amazonaws.com/v1'
    
    def test_api_endpoint_missing(self):
        """API ID가 없을 때 테스트"""
        with patch.dict(os.environ, {}, clear=True):
            settings = Settings()
            
            assert settings.get_api_endpoint('rest') == ''
            assert settings.get_api_endpoint('websocket') == ''
    
    def test_settings_to_dict(self):
        """설정을 딕셔너리로 변환 테스트"""
        with patch.dict(os.environ, {
            'SERVICE_NAME': 'test',
            'ENVIRONMENT': 'dev'
        }):
            settings = Settings()
            config_dict = settings.to_dict()
            
            assert isinstance(config_dict, dict)
            assert 'SERVICE_NAME' in config_dict
            assert 'ENVIRONMENT' in config_dict
            assert config_dict['SERVICE_NAME'] == 'test'
    
    def test_settings_validation(self):
        """설정 검증 테스트"""
        # 모든 필수 설정이 있을 때
        with patch.dict(os.environ, {
            'SERVICE_NAME': 'test',
            'ENVIRONMENT': 'dev',
            'AWS_REGION': 'us-east-1'
        }):
            settings = Settings()
            assert settings.validate() is True
        
        # 필수 설정이 없을 때
        with patch.dict(os.environ, {}, clear=True):
            settings = Settings()
            settings.SERVICE_NAME = ''
            assert settings.validate() is False
    
    def test_table_prefix_suffix(self):
        """테이블 접두사/접미사 테스트"""
        with patch.dict(os.environ, {
            'SERVICE_NAME': 'my-service',
            'STACK_SUFFIX': 'feature-123'
        }):
            settings = Settings()
            
            assert settings.TABLE_PREFIX == 'my-service-'
            assert settings.TABLE_SUFFIX == '-feature-123'
            
            # 새로운 테이블 타입도 패턴 적용
            custom_table = settings.get_table_name('custom')
            assert custom_table == 'my-service-custom-feature-123'