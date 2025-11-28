# 📁 frontend/ - React 프론트엔드

AI 채팅 서비스의 웹 인터페이스를 담당하는 React 애플리케이션입니다.

## 🏗️ 기술 스택
- React 18 + TypeScript
- Vite (빌드 도구)
- Tailwind CSS (스타일링)
- AWS SDK (클라우드 연동)
- WebSocket (실시간 통신)

## 📂 폴더 구조

```
frontend/
├── src/
│   ├── features/        # 기능별 모듈 (핵심 비즈니스 로직)
│   │   ├── auth/       # 로그인, 회원가입, 인증 관리
│   │   ├── chat/       # AI 채팅 인터페이스 및 메시지 처리
│   │   ├── dashboard/  # 사용 통계 및 대시보드
│   │   └── landing/    # 랜딩 페이지 및 소개
│   │
│   ├── shared/         # 공통 컴포넌트 및 유틸리티
│   │   ├── components/ # 재사용 가능한 UI 컴포넌트
│   │   ├── hooks/      # 커스텀 React 훅
│   │   ├── utils/      # 헬퍼 함수 및 유틸리티
│   │   └── types/      # TypeScript 타입 정의
│   │
│   ├── styles/         # 글로벌 스타일 및 테마
│   ├── App.tsx         # 메인 애플리케이션 컴포넌트
│   └── main.tsx        # 엔트리 포인트
│
├── public/             # 정적 파일 (이미지, 아이콘 등)
├── .env               # 환경 변수 (API 엔드포인트 등)
└── package.json       # 프로젝트 의존성
```

## 🔑 주요 기능 모듈

### features/auth/
- **목적**: 사용자 인증 및 권한 관리
- **주요 컴포넌트**:
  - LoginForm: 이메일/비밀번호 로그인
  - SignupForm: 신규 사용자 등록
  - AuthProvider: 인증 상태 관리
- **연동**: AWS Cognito

### features/chat/
- **목적**: AI 채팅 기능의 핵심
- **주요 컴포넌트**:
  - ChatInterface: 메인 채팅 UI
  - MessageList: 대화 내역 표시
  - InputBox: 메시지 입력 및 전송
  - WebSocketManager: 실시간 통신 관리
- **연동**: WebSocket API, Lambda

### features/dashboard/
- **목적**: 사용 현황 시각화
- **주요 컴포넌트**:
  - UsageChart: 사용량 그래프
  - Statistics: 통계 카드
  - History: 대화 기록 관리
- **연동**: REST API

### features/landing/
- **목적**: 서비스 소개 및 온보딩
- **주요 컴포넌트**:
  - Hero: 메인 배너
  - Features: 기능 소개
  - Pricing: 요금제 안내

## 🛠️ 개발 명령어

```bash
# 개발 서버 실행
npm run dev

# 프로덕션 빌드
npm run build

# 빌드 미리보기
npm run preview

# 타입 체크
npm run type-check

# 린트 검사
npm run lint
```

## 🔧 환경 변수

```env
# API 엔드포인트
VITE_REST_API_URL=https://api.example.com
VITE_WEBSOCKET_URL=wss://ws.example.com

# AWS Cognito
VITE_COGNITO_USER_POOL_ID=us-east-1_xxxxx
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxx

# 기타 설정
VITE_AWS_REGION=us-east-1
```

## 📦 주요 의존성
- `react`: UI 라이브러리
- `react-router-dom`: 라우팅
- `aws-amplify`: AWS 서비스 연동
- `axios`: HTTP 클라이언트
- `tailwindcss`: 유틸리티 CSS
- `vite`: 번들러

## ⚠️ 주의사항
- 환경 변수는 VITE_ 접두사 필수
- WebSocket 연결 시 토큰 갱신 확인
- 빌드 시 타입 에러 체크 필수