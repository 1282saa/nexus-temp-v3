# 👋 팀 온보딩 가이드

> 신규 팀원을 위한 프로젝트 시작 가이드

## 📅 Day 1: 환경 설정

### 1. 개발 도구 설치

```bash
# macOS (Homebrew 사용)
brew install node python aws-cli

# Windows (Chocolatey 사용)
choco install nodejs python awscli

# Linux
sudo apt-get install nodejs python3 awscli
```

### 2. 프로젝트 클론 및 설정

```bash
# 저장소 클론
git clone [저장소 URL]
cd nexus-template

# 자동 설정
./setup.sh
```

### 3. IDE 설정

**VS Code 추천 확장:**
- Python (Microsoft)
- ESLint
- Prettier
- AWS Toolkit
- Thunder Client (API 테스트)

**설정 파일 (`.vscode/settings.json`):**
```json
{
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true
}
```

## 📚 Day 2: 코드 이해하기

### 프로젝트 구조 파악

```
🎯 핵심 디렉토리 설명:

backend/
├── handlers/       # 🔌 Lambda 진입점 (요청 처리)
├── services/       # 💼 비즈니스 로직 (핵심 기능)
├── config/         # ⚙️ 설정 관리
└── tests/          # ✅ 테스트 코드

1-frontend/
├── src/
│   ├── components/ # 🎨 UI 컴포넌트
│   ├── hooks/      # 🪝 커스텀 훅
│   └── services/   # 📡 API 통신
```

### 주요 파일 이해

**백엔드 핵심 파일:**
1. `handlers/websocket/message.py` - 채팅 메시지 처리
2. `services/conversation_service.py` - 대화 관리
3. `config/settings.py` - 환경변수 관리

**프론트엔드 핵심 파일:**
1. `src/App.tsx` - 메인 애플리케이션
2. `src/hooks/useWebSocket.ts` - WebSocket 연결
3. `src/services/api.ts` - API 호출

## 🔧 Day 3: 첫 기능 개발

### 예제: 새로운 API 엔드포인트 추가

#### 1. 핸들러 생성
```python
# backend/handlers/api/hello.py
from utils.response import APIResponse

def handler(event, context):
    """새로운 API 핸들러"""
    return APIResponse.success({
        'message': 'Hello, World!'
    })
```

#### 2. serverless.yml에 추가
```yaml
functions:
  helloApi:
    handler: handlers/api/hello.handler
    events:
      - http:
          path: /hello
          method: GET
```

#### 3. 테스트 작성
```python
# backend/tests/unit/test_hello.py
def test_hello_handler():
    from handlers.api.hello import handler
    result = handler({}, {})
    assert result['statusCode'] == 200
```

#### 4. 배포
```bash
cd backend
make deploy-dev
```

## 💡 개발 팁

### 로컬 테스트

```bash
# 백엔드 테스트
cd backend
make test-unit  # 빠른 단위 테스트

# 프론트엔드 테스트
cd 1-frontend
npm test
```

### 디버깅

```bash
# 실시간 로그 보기
cd backend
make logs STAGE=dev

# 특정 함수 로그
serverless logs -f conversationApi --tail
```

### 코드 스타일

```bash
# 자동 포맷팅
make format

# 린트 체크
make lint
```

## 🚀 배포 프로세스

### 브랜치 전략

```
main          → 프로덕션
├── develop   → 개발 통합
│   └── feature/*  → 기능 개발
```

### 배포 절차

1. **기능 개발**
```bash
git checkout -b feature/my-feature
# 코드 작성
git commit -m "feat: Add new feature"
```

2. **테스트**
```bash
make test
```

3. **PR 생성**
```bash
git push origin feature/my-feature
# GitHub에서 PR 생성
```

4. **리뷰 후 머지**
```bash
# develop 브랜치로 자동 배포
```

## 📖 필독 문서

1. **[아키텍처](docs/ARCHITECTURE.md)** - 시스템 설계 이해
2. **[API 문서](docs/API.md)** - 엔드포인트 명세
3. **[트러블슈팅](docs/TROUBLESHOOTING.md)** - 자주 발생하는 문제 해결

## 🆘 도움 받기

### Slack 채널
- `#nexus-dev` - 개발 논의
- `#nexus-help` - 질문과 답변
- `#nexus-deploy` - 배포 알림

### 멘토
- 백엔드: @backend-lead
- 프론트엔드: @frontend-lead
- 인프라: @devops-lead

### 유용한 명령어 모음

```bash
# 🔍 자주 사용하는 명령어

# 전체 설정
./setup.sh

# 백엔드 작업
cd backend
make test          # 테스트
make deploy-dev    # 개발 배포
make logs          # 로그 확인

# 프론트엔드 작업
cd 1-frontend
npm run dev        # 개발 서버
npm run build      # 빌드

# Git 작업
git status         # 상태 확인
git pull           # 최신 코드 받기
git push           # 코드 푸시
```

## ✅ 체크리스트

### 첫 주 완료 목표
- [ ] 개발 환경 설정 완료
- [ ] 프로젝트 구조 이해
- [ ] 로컬에서 실행 성공
- [ ] 간단한 기능 하나 추가
- [ ] 첫 PR 생성

### 첫 달 목표
- [ ] 주요 코드베이스 이해
- [ ] 독립적으로 기능 개발
- [ ] 코드 리뷰 참여
- [ ] 배포 프로세스 이해

## 🎓 학습 자료

### 필수 개념
- [AWS Lambda 이해하기](https://docs.aws.amazon.com/lambda/)
- [DynamoDB 기초](https://docs.aws.amazon.com/dynamodb/)
- [WebSocket 개념](https://developer.mozilla.org/ko/docs/Web/API/WebSocket)

### 추천 강의
- [Serverless Framework 입문](https://www.serverless.com/learn/)
- [React + TypeScript](https://react.dev/learn)

## 🎉 환영합니다!

질문이 있으시면 언제든 팀 채널에 문의하세요. 
함께 훌륭한 제품을 만들어갑시다! 🚀