# 📁 backend/ - Python Lambda 백엔드

AI 채팅 서비스의 서버리스 백엔드 로직을 담당하는 Lambda 함수들입니다.

## 🏗️ 기술 스택
- Python 3.11
- AWS Lambda (서버리스 컴퓨팅)
- Amazon Bedrock (AI 모델)
- DynamoDB (NoSQL 데이터베이스)
- API Gateway (REST + WebSocket)

## 📂 단순화된 폴더 구조

```
backend/
├── config/               # 설정 파일
│   ├── __init__.py      
│   ├── aws.py           # AWS 설정 (리전, Bedrock 설정)
│   └── database.py      # 데이터베이스 테이블 설정
│
├── handlers/            # Lambda 함수 핸들러 (진입점)
│   ├── api/            # REST API 핸들러
│   │   ├── conversation.py  # 대화 관리 API
│   │   ├── prompt.py        # 프롬프트 CRUD
│   │   └── usage.py         # 사용량 추적
│   │
│   └── websocket/      # WebSocket 핸들러
│       ├── connect.py      # 연결 수립
│       ├── disconnect.py   # 연결 종료
│       └── message.py      # 메시지 처리
│
├── services/           # 비즈니스 로직 (통합)
│   ├── conversation_service.py  # 대화 관리 + 모델 + Repository
│   ├── conversation_manager.py  # 대화 헬퍼 함수
│   ├── prompt_service.py       # 프롬프트 관리
│   ├── usage_service.py        # 사용량 관리
│   └── websocket_service.py    # WebSocket 메시지 처리
│
├── lib/                # 외부 서비스 클라이언트
│   └── bedrock_client_enhanced.py  # Bedrock AI 클라이언트
│
└── utils/              # 유틸리티 함수
    ├── logger.py       # 로깅 설정
    └── response.py     # API 응답 포맷
```

## 🔑 주요 특징

### 단순화된 구조
- **2단계 깊이**: 복잡한 중첩 구조 제거
- **통합 서비스**: Model, Repository, Service를 하나의 파일에
- **명확한 역할**: 각 폴더의 목적이 분명

### 핵심 파일 설명

#### services/conversation_service.py
```python
# 대화 관련 모든 기능을 하나의 파일에 통합
# Message, Conversation 모델 정의
# ConversationRepository (DynamoDB 접근)
# ConversationService (비즈니스 로직)

@dataclass
class Message:
    """메시지 모델"""
    role: str
    content: str
    
@dataclass
class Conversation:
    """대화 모델"""
    conversation_id: str
    user_id: str
    messages: List[Message]
    
class ConversationRepository:
    """DynamoDB 접근 계층"""
    
class ConversationService:
    """비즈니스 로직"""
```

## 📦 배포 구조

Lambda 배포 시 이 폴더 전체가 ZIP으로 패키징됩니다:

```bash
# 배포 패키지 생성
cd backend
zip -r lambda-deployment.zip . \
  -x "*.pyc" \
  -x "__pycache__/*" \
  -x ".env*" \
  -x "*.md"
```

## 🗄️ DynamoDB 테이블

| 테이블명 | 용도 | 주요 필드 |
|---------|------|-----------|
| conversations | 대화 세션 | conversationId (PK), userId (GSI) |
| messages | 채팅 메시지 | messageId, conversationId |
| prompts | 프롬프트 템플릿 | promptId, name |
| usage | 사용량 추적 | userId, date |
| websocket-connections | WS 연결 | connectionId |

## 🤖 AI 모델 통합

Amazon Bedrock을 통한 Claude 모델 사용:
```python
# lib/bedrock_client_enhanced.py
MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
```

## 🔧 환경 변수

```env
# 서비스 설정
SERVICE_NAME=my-nexus
ENVIRONMENT=dev
AWS_REGION=us-east-1

# 테이블 이름 (자동 생성)
CONVERSATIONS_TABLE=${SERVICE_NAME}-conversations-${ENVIRONMENT}
PROMPTS_TABLE=${SERVICE_NAME}-prompts-${ENVIRONMENT}
```

## 🚀 로컬 테스트

```bash
# Python 가상환경 설정
python -m venv venv
source venv/bin/activate  # Mac/Linux
# or
venv\Scripts\activate  # Windows

# 의존성 설치
pip install boto3 python-jose

# 테스트 실행
python -m handlers.api.conversation
```

## 📝 Import 예시

단순화된 import 구조:
```python
# handlers/api/conversation.py
from services.conversation_service import ConversationService, Message
from utils.response import APIResponse
from utils.logger import setup_logger

# handlers/websocket/message.py
from services.websocket_service import WebSocketService
from services.conversation_manager import ConversationManager
```

## ⚠️ 주의사항
- Lambda 실행 시간 제한: 120초
- 페이로드 크기 제한: 6MB (동기), 256KB (비동기)
- 환경변수에 민감 정보 저장 금지
- __pycache__ 폴더는 배포에서 제외