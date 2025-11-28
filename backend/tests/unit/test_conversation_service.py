"""
ConversationService 단위 테스트
"""
import pytest
from unittest.mock import Mock, patch
from datetime import datetime
import uuid

from services.conversation_service import (
    Message, Conversation, ConversationRepository, ConversationService
)


class TestMessage:
    """Message 모델 테스트"""
    
    def test_message_creation(self):
        """메시지 생성 테스트"""
        msg = Message(
            role='user',
            content='Hello',
            timestamp='2024-01-01T00:00:00Z'
        )
        assert msg.role == 'user'
        assert msg.content == 'Hello'
        assert msg.timestamp == '2024-01-01T00:00:00Z'
    
    def test_message_with_metadata(self):
        """메타데이터가 있는 메시지 테스트"""
        metadata = {'source': 'api', 'version': '1.0'}
        msg = Message(
            role='assistant',
            content='Response',
            metadata=metadata
        )
        assert msg.metadata == metadata


class TestConversation:
    """Conversation 모델 테스트"""
    
    def test_conversation_creation(self):
        """대화 생성 테스트"""
        conv = Conversation(
            conversation_id='test-123',
            user_id='user-123',
            engine_type='11',
            title='Test Chat'
        )
        assert conv.conversation_id == 'test-123'
        assert conv.user_id == 'user-123'
        assert conv.engine_type == '11'
        assert conv.title == 'Test Chat'
    
    def test_conversation_to_dict(self):
        """대화를 딕셔너리로 변환 테스트"""
        msg = Message(role='user', content='Hello')
        conv = Conversation(
            conversation_id='test-123',
            user_id='user-123',
            engine_type='11',
            messages=[msg]
        )
        
        result = conv.to_dict()
        
        assert result['conversationId'] == 'test-123'
        assert result['userId'] == 'user-123'
        assert result['engineType'] == '11'
        assert len(result['messages']) == 1
        assert result['messages'][0]['content'] == 'Hello'
    
    def test_conversation_from_dict(self):
        """딕셔너리에서 대화 생성 테스트"""
        data = {
            'conversationId': 'test-123',
            'userId': 'user-123',
            'engineType': '11',
            'messages': [
                {'role': 'user', 'content': 'Hello'}
            ]
        }
        
        conv = Conversation.from_dict(data)
        
        assert conv.conversation_id == 'test-123'
        assert conv.user_id == 'user-123'
        assert len(conv.messages) == 1
        assert conv.messages[0].content == 'Hello'


class TestConversationRepository:
    """ConversationRepository 테스트"""
    
    @patch('services.conversation_service.boto3.resource')
    def test_repository_initialization(self, mock_resource):
        """리포지토리 초기화 테스트"""
        mock_table = Mock()
        mock_resource.return_value.Table.return_value = mock_table
        
        repo = ConversationRepository()
        
        assert repo.table == mock_table
    
    @patch('services.conversation_service.boto3.resource')
    def test_save_conversation(self, mock_resource):
        """대화 저장 테스트"""
        mock_table = Mock()
        mock_resource.return_value.Table.return_value = mock_table
        
        repo = ConversationRepository()
        conv = Conversation(
            conversation_id=None,  # 자동 생성
            user_id='user-123',
            engine_type='11'
        )
        
        with patch('uuid.uuid4', return_value='generated-id'):
            result = repo.save(conv)
        
        assert result.conversation_id is not None
        mock_table.put_item.assert_called_once()
    
    @patch('services.conversation_service.boto3.resource')
    def test_get_conversation(self, mock_resource):
        """대화 조회 테스트"""
        mock_table = Mock()
        mock_table.get_item.return_value = {
            'Item': {
                'conversationId': 'test-123',
                'userId': 'user-123',
                'engineType': '11',
                'messages': []
            }
        }
        mock_resource.return_value.Table.return_value = mock_table
        
        repo = ConversationRepository()
        result = repo.get('test-123')
        
        assert result is not None
        assert result.conversation_id == 'test-123'
        mock_table.get_item.assert_called_once_with(
            Key={'conversationId': 'test-123'}
        )
    
    @patch('services.conversation_service.boto3.resource')
    def test_delete_conversation(self, mock_resource):
        """대화 삭제 테스트"""
        mock_table = Mock()
        mock_resource.return_value.Table.return_value = mock_table
        
        repo = ConversationRepository()
        result = repo.delete('test-123')
        
        assert result is True
        mock_table.delete_item.assert_called_once_with(
            Key={'conversationId': 'test-123'}
        )


class TestConversationService:
    """ConversationService 테스트"""
    
    @patch('services.conversation_service.ConversationRepository')
    def test_service_initialization(self, mock_repo_class):
        """서비스 초기화 테스트"""
        service = ConversationService()
        assert service.repository is not None
    
    @patch('services.conversation_service.ConversationRepository')
    def test_create_conversation(self, mock_repo_class):
        """대화 생성 테스트"""
        mock_repo = Mock()
        mock_repo.save.return_value = Conversation(
            conversation_id='test-123',
            user_id='user-123',
            engine_type='11'
        )
        mock_repo_class.return_value = mock_repo
        
        service = ConversationService()
        result = service.create_conversation(
            user_id='user-123',
            engine_type='11',
            initial_message='Hello'
        )
        
        assert result.conversation_id == 'test-123'
        assert result.user_id == 'user-123'
    
    @patch('services.conversation_service.ConversationRepository')
    def test_add_message(self, mock_repo_class):
        """메시지 추가 테스트"""
        existing_conv = Conversation(
            conversation_id='test-123',
            user_id='user-123',
            engine_type='11',
            messages=[]
        )
        
        mock_repo = Mock()
        mock_repo.get.return_value = existing_conv
        mock_repo.save.return_value = existing_conv
        mock_repo_class.return_value = mock_repo
        
        service = ConversationService()
        result = service.add_message(
            conversation_id='test-123',
            role='user',
            content='New message'
        )
        
        assert len(result.messages) == 1
        assert result.messages[0].content == 'New message'
    
    @patch('services.conversation_service.ConversationRepository')
    def test_get_conversation_not_found(self, mock_repo_class):
        """존재하지 않는 대화 조회 테스트"""
        mock_repo = Mock()
        mock_repo.get.return_value = None
        mock_repo_class.return_value = mock_repo
        
        service = ConversationService()
        result = service.get_conversation('non-existent')
        
        assert result is None