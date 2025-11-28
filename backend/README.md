# 📁 backend/ - Python Lambda 백엔드

AI 채팅 서비스의 서버리스 백엔드 로직을 담당하는 Lambda 함수들입니다.

## 🏗️ 기술 스택
- Python 3.11
- AWS Lambda (서버리스 컴퓨팅)
- Amazon Bedrock (AI 모델)
- DynamoDB (NoSQL 데이터베이스)
- API Gateway (REST + WebSocket)

## 📂 폴더 구조 (간소화됨)

```
backend/
├── handlers/              # Lambda 함수 핸들러
│   ├── api/              # REST API 핸들러
│   │   ├── conversation.py  # 대화 관리 API
│   │   ├── prompt.py        # 프롬프트 CRUD
│   │   └── usage.py         # 사용량 추적
│   │
│   └── websocket/        # WebSocket 핸들러
│       ├── connect.py    # 연결 수립
│       ├── disconnect.py # 연결 종료
│       ├── message.py    # 메시지 처리
│       └── conversation_manager.py # 대화 관리 헬퍼
│
├── src/                  # 핵심 비즈니스 로직
│   ├── config/          # 설정 파일
│   │   ├── aws.py       # AWS 설정
│   │   └── database.py  # DB 설정
│   │
│   ├── models/          # 데이터 모델
│   │   ├── conversation.py
│   │   ├── prompt.py
│   │   └── usage.py
│   │
│   ├── repositories/    # 데이터 저장소
│   │   ├── conversation_repository.py
│   │   ├── prompt_repository.py
│   │   └── usage_repository.py
│   │
│   └── services/        # 비즈니스 로직
│       ├── conversation_service.py
│       ├── prompt_service.py
│       └── usage_service.py
│
├── lib/                  # 외부 라이브러리
│   └── bedrock_client_enhanced.py # Bedrock AI 클라이언트
│
├── services/             # WebSocket 서비스
│   └── websocket_service.py
│
├── utils/                # 유틸리티
│   ├── logger.py        # 로깅 설정
│   └── response.py      # API 응답 포맷
│
└── .env                  # 환경 변수
```

## 📦 배포 구조

이 폴더의 모든 내용이 ZIP으로 패키징되어 Lambda에 배포됩니다:
- README.md와 .env는 배포에서 제외
- __pycache__ 폴더는 자동 제외

## 🔑 주요 Lambda 함수

### handlers/api/conversation.py
```python
# 대화 세션을 관리하는 Lambda 핸들러
# GET: 대화 목록 조회
# POST: 새 대화 생성
# DELETE: 대화 삭제
def handler(event, context):
    """대화 관리 API 핸들러"""
    # HTTP 메서드에 따라 분기 처리
    # DynamoDB에 대화 데이터 저장/조회
```

### handlers/api/prompt.py
```python
# AI 프롬프트를 관리하는 Lambda 핸들러
# CRUD 작업 지원
def handler(event, context):
    """프롬프트 관리 API 핸들러"""
    # 프롬프트 템플릿 저장/수정/삭제
    # 버전 관리 지원
```

### handlers/api/usage.py
```python
# 사용량과 비용을 추적하는 Lambda 핸들러
def handler(event, context):
    """사용량 추적 API 핸들러"""
    # 토큰 사용량 계산
    # 비용 집계
    # 사용 통계 제공
```

### handlers/websocket/connect.py
```python
# WebSocket 연결을 처리하는 Lambda 핸들러
def handler(event, context):
    """WebSocket 연결 핸들러"""
    # 연결 ID 저장
    # 인증 토큰 검증
    # DynamoDB에 연결 정보 기록
```

### handlers/websocket/disconnect.py
```python
# WebSocket 연결 해제를 처리하는 Lambda 핸들러
def handler(event, context):
    """WebSocket 연결 해제 핸들러"""
    # 연결 ID 제거
    # 정리 작업 수행
```

### handlers/websocket/message.py
```python
# WebSocket 메시지를 처리하는 Lambda 핸들러
def handler(event, context):
    """WebSocket 메시지 핸들러"""
    # 메시지 파싱
    # Bedrock AI 호출
    # 스트리밍 응답 전송
```

## 🗄️ DynamoDB 테이블 구조

| 테이블명 | 용도 | 주요 필드 |
|---------|------|-----------|
| conversations | 대화 세션 | conversation_id, user_id, created_at |
| messages | 채팅 메시지 | message_id, conversation_id, content |
| prompts | 프롬프트 템플릿 | prompt_id, name, template |
| usage | 사용량 추적 | user_id, tokens_used, cost |
| websocket-connections | WS 연결 관리 | connection_id, user_id |
| files | 파일 첨부 | file_id, s3_key, metadata |

## 🤖 AI 모델 통합

### Amazon Bedrock 설정
```python
# Claude 3 모델 사용
MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"

# 스트리밍 응답 지원
response = bedrock.invoke_model_with_response_stream(
    modelId=MODEL_ID,
    body=request_body
)
```

## 📦 주요 의존성
- `boto3`: AWS SDK
- `python-jose`: JWT 토큰 처리
- `pydantic`: 데이터 검증
- `python-dateutil`: 날짜 처리

## 🔧 환경 변수

```env
# AWS 설정
AWS_REGION=us-east-1
SERVICE_NAME=my-nexus
ENVIRONMENT=dev

# DynamoDB 테이블
CONVERSATIONS_TABLE=conversations
MESSAGES_TABLE=messages
PROMPTS_TABLE=prompts

# Bedrock
BEDROCK_MODEL_ID=claude-3-sonnet

# 로깅
LOG_LEVEL=INFO
```

## 🚀 배포 프로세스

1. `3-deploy/deploy-backend.sh` 스크립트 실행
2. 자동으로 ZIP 패키징 및 Lambda 함수 업데이트
3. 6개 함수 동시 배포

## ⚠️ 주의사항
- Lambda 실행 시간 제한: 120초
- 페이로드 크기 제한: 6MB (동기), 256KB (비동기)
- 콜드 스타트 최적화 필요
- 환경변수에 민감 정보 저장 금지