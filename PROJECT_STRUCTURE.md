# NEXUS Template 프로젝트 구조

## 📁 폴더 구조 개요

```
nexus-v2/title/
├── 1-setup/                # 초기 설정 및 구성
│   ├── configure.sh        # 대화형 설정 마법사
│   └── setup.sh           # 빠른 설정 (기본값)
│
├── 2-infrastructure/       # AWS 인프라 생성
│   ├── create-infrastructure.sh  # 통합 인프라 생성
│   ├── create-lambda.sh        # Lambda 함수 6개
│   ├── create-api-gateway.sh   # REST + WebSocket API
│   ├── create-cognito.sh       # 사용자 인증
│   └── create-cloudfront.sh    # CDN 배포
│
├── 3-deploy/              # 배포 스크립트
│   ├── deploy.sh          # 스마트 배포 (변경 감지)
│   ├── deploy-frontend.sh # React 앱 -> S3
│   └── deploy-backend.sh  # Python 코드 -> Lambda
│
├── 4-utilities/           # 유틸리티
│   └── generate-env.sh    # 환경 변수 생성
│
├── frontend/              # React 프론트엔드
│   └── src/
│       ├── features/      # 기능별 모듈
│       │   ├── auth/      # 로그인/회원가입
│       │   ├── chat/      # 채팅 기능
│       │   ├── dashboard/ # 대시보드
│       │   └── landing/   # 랜딩 페이지
│       └── shared/        # 공통 컴포넌트
│
└── backend/               # Python Lambda 백엔드
    └── handlers/
        ├── api/           # REST API 핸들러
        │   ├── prompt.py  # 프롬프트 관리
        │   ├── usage.py   # 사용량 추적
        │   └── conversation.py # 대화 관리
        └── websocket/     # WebSocket 핸들러
            ├── connect.py    # 연결 처리
            ├── disconnect.py # 연결 해제
            └── message.py    # 메시지 처리
```

## 🔑 주요 파일 설명

### 시작 스크립트

- `quick-start.sh`: 비개발자용 원클릭 설치
- `start.sh`: 대화형 메뉴 시스템

### 설정 파일

- `.env.deploy.template`: 배포 설정 템플릿
- `config.template.json`: 서비스 설정 템플릿
- `.gitignore`: Git 제외 파일 (민감 정보 보호)

### 문서

- `README.md`: 프로젝트 사용 가이드
- `PROJECT_STRUCTURE.md`: 이 문서

## 🏗️ AWS 리소스 매핑

| 폴더/파일                     | AWS 리소스       | 설명           |
| ----------------------------- | ---------------- | -------------- |
| backend/handlers/api/\*       | Lambda Functions | REST API 처리  |
| backend/handlers/websocket/\* | Lambda Functions | 실시간 통신    |
| frontend/dist/\*              | S3 Bucket        | 정적 웹 호스팅 |
| -                             | CloudFront       | CDN 배포       |
| -                             | API Gateway      | API 엔드포인트 |
| -                             | Cognito          | 사용자 인증    |
| -                             | DynamoDB         | 데이터 저장    |

## 💡 개발 시 주의사항

1. **환경 변수**: `.env` 파일은 절대 커밋하지 않음
2. **AWS 인증**: 스크립트 실행 전 `aws configure` 필수
3. **의존성**: Node.js 18+, Python 3.9+ 필요
4. **순서**: 설정 → 인프라 → 배포 순서 준수

## 🔧 커스터마이징 포인트

- `frontend/src/features/`: 새 기능 추가
- `backend/handlers/`: API 로직 수정
- `frontend/public/images/`: 로고/이미지 변경
- 프롬프트: `backend/handlers/api/prompt.py`
