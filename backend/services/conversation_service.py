"""
대화(Conversation) 비즈니스 로직 및 모델
Message, Conversation 모델과 Repository를 포함한 통합 서비스
"""
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import boto3
import uuid
from decimal import Decimal

logger = logging.getLogger(__name__)

# ================== 모델 정의 ==================
@dataclass
class Message:
    """메시지 모델"""
    role: str  # 'user' or 'assistant'
    content: str
    timestamp: Optional[str] = None
    type: Optional[str] = None  # 'user' or 'assistant' - 프론트엔드 호환성
    metadata: Optional[Dict[str, Any]] = field(default_factory=dict)


@dataclass
class Conversation:
    """대화 모델"""
    conversation_id: str
    user_id: str
    engine_type: str  # 'C1' or 'C2'
    title: Optional[str] = None
    messages: List[Message] = field(default_factory=list)
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """DynamoDB 저장용 딕셔너리 변환"""
        return {
            'conversationId': self.conversation_id,
            'userId': self.user_id,
            'engineType': self.engine_type,
            'title': self.title,
            'messages': [
                {
                    'role': msg.role,
                    'type': msg.type or msg.role,  # type 필드 추가 (role과 동일)
                    'content': msg.content,
                    'timestamp': msg.timestamp,
                    'metadata': msg.metadata
                }
                for msg in self.messages
            ],
            'createdAt': self.created_at or datetime.now().isoformat(),
            'updatedAt': self.updated_at or datetime.now().isoformat(),
            'metadata': self.metadata
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Conversation':
        """DynamoDB 데이터에서 모델 생성"""
        messages = []
        for msg_data in data.get('messages', []):
            messages.append(Message(
                role=msg_data.get('role', msg_data.get('type', 'user')),
                type=msg_data.get('type', msg_data.get('role', 'user')),
                content=msg_data.get('content', ''),
                timestamp=msg_data.get('timestamp'),
                metadata=msg_data.get('metadata', {})
            ))
        
        return cls(
            conversation_id=data.get('conversationId'),
            user_id=data.get('userId'),
            engine_type=data.get('engineType'),
            title=data.get('title'),
            messages=messages,
            created_at=data.get('createdAt'),
            updated_at=data.get('updatedAt'),
            metadata=data.get('metadata', {})
        )


# ================== Repository ==================
class ConversationRepository:
    """대화 저장소 - DynamoDB 접근"""
    
    def __init__(self, table_name: Optional[str] = None):
        import os
        self.dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        # f1 서비스용 테이블 설정
        self.table_name = table_name or os.environ.get('CONVERSATIONS_TABLE', 'f1-conversations-two')
        self.table = self.dynamodb.Table(self.table_name)
        logger.info(f"ConversationRepository initialized with table: {self.table_name}")
    
    def save(self, conversation: Conversation) -> Conversation:
        """대화 저장 (생성 또는 업데이트)"""
        try:
            # ID 자동 생성
            if not conversation.conversation_id:
                conversation.conversation_id = str(uuid.uuid4())
            
            # 타임스탬프 설정
            now = datetime.now().isoformat()
            if not conversation.created_at:
                conversation.created_at = now
            conversation.updated_at = now
            
            # DynamoDB 저장
            item = conversation.to_dict()
            self.table.put_item(Item=item)
            
            logger.info(f"Conversation saved: {conversation.conversation_id}")
            return conversation
            
        except Exception as e:
            logger.error(f"Error saving conversation: {str(e)}")
            raise
    
    def find_by_id(self, conversation_id: str) -> Optional[Conversation]:
        """ID로 대화 조회"""
        try:
            response = self.table.get_item(
                Key={'conversationId': conversation_id}
            )
            
            if 'Item' in response:
                return Conversation.from_dict(response['Item'])
            return None
            
        except Exception as e:
            logger.error(f"Error finding conversation by id: {str(e)}")
            raise
    
    def find_by_user(self, user_id: str, limit: int = 1000) -> List[Conversation]:
        """사용자별 대화 조회"""
        try:
            # GSI를 사용하여 userId로 조회
            response = self.table.query(
                IndexName='userId-createdAt-index',
                KeyConditionExpression='userId = :uid',
                ExpressionAttributeValues={
                    ':uid': user_id
                },
                Limit=limit,
                ScanIndexForward=False  # 최신순 정렬
            )
            
            conversations = []
            for item in response.get('Items', []):
                conversations.append(Conversation.from_dict(item))
            
            # 페이지네이션 처리
            while 'LastEvaluatedKey' in response and len(conversations) < limit:
                response = self.table.query(
                    IndexName='userId-createdAt-index',
                    KeyConditionExpression='userId = :uid',
                    ExpressionAttributeValues={
                        ':uid': user_id
                    },
                    ExclusiveStartKey=response['LastEvaluatedKey'],
                    Limit=limit - len(conversations),
                    ScanIndexForward=False
                )
                
                for item in response.get('Items', []):
                    conversations.append(Conversation.from_dict(item))
            
            logger.info(f"Found {len(conversations)} conversations for user: {user_id}")
            return conversations
            
        except Exception as e:
            logger.error(f"Error finding conversations by user: {str(e)}")
            # GSI가 없는 경우 scan 사용
            try:
                response = self.table.scan(
                    FilterExpression='userId = :uid',
                    ExpressionAttributeValues={
                        ':uid': user_id
                    }
                )
                
                conversations = []
                for item in response.get('Items', []):
                    conversations.append(Conversation.from_dict(item))
                
                logger.info(f"Found {len(conversations)} conversations for user (scan): {user_id}")
                return conversations[:limit]
                
            except Exception as fallback_error:
                logger.error(f"Fallback scan also failed: {str(fallback_error)}")
                return []
    
    def update_messages(self, conversation_id: str, messages: List[Message]) -> bool:
        """메시지 업데이트"""
        try:
            messages_dict = [
                {
                    'role': msg.role,
                    'type': msg.type or msg.role,
                    'content': msg.content,
                    'timestamp': msg.timestamp or datetime.now().isoformat(),
                    'metadata': msg.metadata or {}
                }
                for msg in messages
            ]
            
            self.table.update_item(
                Key={'conversationId': conversation_id},
                UpdateExpression='SET messages = :messages, updatedAt = :updated',
                ExpressionAttributeValues={
                    ':messages': messages_dict,
                    ':updated': datetime.now().isoformat()
                }
            )
            
            logger.info(f"Updated {len(messages)} messages for conversation: {conversation_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating messages: {str(e)}")
            return False
    
    def update_title(self, conversation_id: str, title: str) -> bool:
        """제목 업데이트"""
        try:
            self.table.update_item(
                Key={'conversationId': conversation_id},
                UpdateExpression='SET title = :title, updatedAt = :updated',
                ExpressionAttributeValues={
                    ':title': title,
                    ':updated': datetime.now().isoformat()
                }
            )
            
            logger.info(f"Updated title for conversation: {conversation_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating title: {str(e)}")
            return False
    
    def delete(self, conversation_id: str) -> bool:
        """대화 삭제"""
        try:
            self.table.delete_item(
                Key={'conversationId': conversation_id}
            )
            
            logger.info(f"Deleted conversation: {conversation_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting conversation: {str(e)}")
            return False
    
    def find_recent(self, user_id: str, engine_type: Optional[str], days: int) -> List[Conversation]:
        """최근 대화 조회"""
        try:
            cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
            
            # GSI를 사용하여 userId로 조회
            response = self.table.query(
                IndexName='userId-createdAt-index',
                KeyConditionExpression='userId = :uid AND createdAt > :cutoff',
                ExpressionAttributeValues={
                    ':uid': user_id,
                    ':cutoff': cutoff_date
                },
                ScanIndexForward=False
            )
            
            conversations = []
            for item in response.get('Items', []):
                conv = Conversation.from_dict(item)
                # engine_type 필터링
                if engine_type is None or conv.engine_type == engine_type:
                    conversations.append(conv)
            
            return conversations
            
        except Exception as e:
            logger.error(f"Error finding recent conversations: {str(e)}")
            return []


# ================== Service ==================
class ConversationService:
    """대화 관련 비즈니스 로직"""
    
    def __init__(self, repository: Optional[ConversationRepository] = None):
        self.repository = repository or ConversationRepository()
    
    def create_conversation(
        self,
        user_id: str,
        engine_type: str,
        title: Optional[str] = None,
        initial_message: Optional[str] = None
    ) -> Conversation:
        """새 대화 생성"""
        try:
            # 대화 모델 생성
            conversation = Conversation(
                conversation_id='',  # 자동 생성
                user_id=user_id,
                engine_type=engine_type,
                title=title or f"새 대화 - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
            )
            
            # 초기 메시지 추가
            if initial_message:
                message = Message(
                    role='user',
                    content=initial_message,
                    timestamp=datetime.now().isoformat()
                )
                conversation.messages.append(message)
            
            # 저장
            saved = self.repository.save(conversation)
            logger.info(f"Conversation created: {saved.conversation_id}")
            
            return saved
            
        except Exception as e:
            logger.error(f"Error creating conversation: {str(e)}")
            raise
    
    def get_conversation(self, conversation_id: str) -> Optional[Conversation]:
        """대화 조회"""
        try:
            return self.repository.find_by_id(conversation_id)
        except Exception as e:
            logger.error(f"Error getting conversation: {str(e)}")
            raise
    
    def get_user_conversations(
        self,
        user_id: str,
        limit: int = 1000
    ) -> List[Conversation]:
        """사용자의 대화 목록 조회 - 모든 대화 반환"""
        try:
            return self.repository.find_by_user(user_id, limit)
        except Exception as e:
            logger.error(f"Error getting user conversations: {str(e)}")
            raise
    
    def add_message(
        self,
        conversation_id: str,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """대화에 메시지 추가"""
        try:
            # 기존 대화 조회
            conversation = self.repository.find_by_id(conversation_id)
            if not conversation:
                raise ValueError(f"Conversation not found: {conversation_id}")
            
            # 새 메시지 생성
            message = Message(
                role=role,
                content=content,
                timestamp=datetime.now().isoformat(),
                metadata=metadata or {}
            )
            
            # 메시지 추가
            conversation.messages.append(message)
            
            # 업데이트
            return self.repository.update_messages(conversation_id, conversation.messages)
            
        except Exception as e:
            logger.error(f"Error adding message: {str(e)}")
            raise
    
    def update_title(self, conversation_id: str, title: str) -> bool:
        """대화 제목 업데이트"""
        try:
            logger.info(f"ConversationService.update_title called: {conversation_id} -> {title}")
            result = self.repository.update_title(conversation_id, title)
            logger.info(f"Repository update_title returned: {result}")
            return result
        except Exception as e:
            logger.error(f"Error in ConversationService.update_title: {str(e)}")
            logger.error(f"Exception details: {type(e).__name__}: {str(e)}")
            raise
    
    def delete_conversation(self, conversation_id: str) -> bool:
        """대화 삭제"""
        try:
            return self.repository.delete(conversation_id)
        except Exception as e:
            logger.error(f"Error deleting conversation: {str(e)}")
            raise
    
    def get_recent_conversations(
        self,
        user_id: str,
        engine_type: Optional[str] = None,
        days: int = 30
    ) -> List[Conversation]:
        """최근 대화 조회"""
        try:
            return self.repository.find_recent(user_id, engine_type, days)
        except Exception as e:
            logger.error(f"Error getting recent conversations: {str(e)}")
            raise
    
    def generate_title_from_messages(self, messages: List[Message]) -> str:
        """메시지 내용에서 제목 생성"""
        try:
            if not messages:
                return "새 대화"
            
            # 첫 사용자 메시지 찾기
            for message in messages:
                if message.role == 'user' and message.content:
                    # 첫 30자 + 요약
                    content = message.content.strip()
                    if len(content) > 30:
                        return content[:30] + "..."
                    return content
            
            return "새 대화"
            
        except Exception as e:
            logger.error(f"Error generating title: {str(e)}")
            return "새 대화"
    
    def validate_conversation_access(
        self,
        conversation_id: str,
        user_id: str
    ) -> bool:
        """대화 접근 권한 검증"""
        try:
            conversation = self.repository.find_by_id(conversation_id)
            if not conversation:
                return False
            
            return conversation.user_id == user_id
            
        except Exception as e:
            logger.error(f"Error validating access: {str(e)}")
            return False
    
    def get_conversation_statistics(self, user_id: str) -> Dict[str, Any]:
        """사용자의 대화 통계"""
        try:
            conversations = self.repository.find_by_user(user_id, limit=100)
            
            stats = {
                'total_conversations': len(conversations),
                'by_engine': {},
                'total_messages': 0,
                'avg_messages_per_conversation': 0
            }
            
            # 엔진별 집계
            for conv in conversations:
                engine = conv.engine_type
                if engine not in stats['by_engine']:
                    stats['by_engine'][engine] = 0
                stats['by_engine'][engine] += 1
                
                # 메시지 수 집계
                stats['total_messages'] += len(conv.messages)
            
            # 평균 계산
            if stats['total_conversations'] > 0:
                stats['avg_messages_per_conversation'] = (
                    stats['total_messages'] / stats['total_conversations']
                )
            
            return stats
            
        except Exception as e:
            logger.error(f"Error getting statistics: {str(e)}")
            raise