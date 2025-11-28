# Backend 폴더 구조 분석 결과

## 📊 현재 폴더별 사용 현황

### ✅ 실제 사용되는 폴더

1. **handlers/** - Lambda 핸들러 (핵심)
   - `api/` - REST API 핸들러 3개 (conversation, prompt, usage)
   - `websocket/` - WebSocket 핸들러 4개 (connect, disconnect, message, conversation_manager)
   - 모든 Lambda 함수의 진입점

2. **utils/** - 유틸리티 (사용됨)
   - `logger.py` - 모든 핸들러에서 사용
   - `response.py` - API 응답 포맷팅에 사용

3. **lib/** - 외부 서비스 클라이언트 (사용됨)
   - `bedrock_client_enhanced.py` - AI 모델 호출에 필수

4. **services/** - 비즈니스 로직 (부분 사용)
   - `websocket_service.py` - WebSocket 메시지 처리에서 사용

### ⚠️ 부분적으로 사용되는 폴더

5. **src/** - 구조화된 코드 (일부만 사용)
   - `config/` - 설정 파일 (7곳에서만 import)
   - `services/` - conversation_service만 사용
   - `models/` - Message 모델만 가끔 사용
   - `repositories/` - 거의 사용 안 됨

## 🔍 문제점 발견

### 1. 중복된 구조
- `services/` 폴더가 2개 존재 (루트와 src 내부)
- `ConversationManager`가 handlers/websocket에 있음 (services에 있어야 논리적)

### 2. 불일치된 import 패턴
```python
# 일부는 src를 사용
from src.services.conversation_service import ConversationService

# 일부는 직접 참조
from services.websocket_service import WebSocketService
from handlers.websocket.conversation_manager import ConversationManager
```

### 3. 사용되지 않는 코드
- `src/repositories/` - Repository 패턴이 구현되어 있지만 실제로 사용 안 됨
- 대부분의 핸들러가 직접 DynamoDB를 호출

## 💡 최적화 제안

### Option 1: 단순 구조 (권장)
```
backend/
├── handlers/        # Lambda 핸들러
│   ├── api/        
│   └── websocket/   
├── services/        # 모든 비즈니스 로직
├── lib/            # 외부 클라이언트
├── utils/          # 유틸리티
└── config/         # 설정 파일
```

### Option 2: 현재 구조 정리
- src 폴더를 완전히 활용하거나 제거
- import 경로 통일
- 중복 제거

## 📋 즉시 가능한 개선사항

1. **ConversationManager 이동**
   - `handlers/websocket/conversation_manager.py` → `services/conversation_manager.py`

2. **중복 services 폴더 통합**
   - src/services와 루트 services를 하나로 통합

3. **사용하지 않는 repositories 제거**
   - 실제로 사용되지 않으므로 제거 고려

4. **import 경로 통일**
   - 모든 import를 일관된 패턴으로 수정