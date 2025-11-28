# 🚀 Nexus - AI Chat Service Template

> **원클릭으로 배포 가능한 엔터프라이즈급 AI 채팅 서비스 템플릿**

[![AWS](https://img.shields.io/badge/AWS-Serverless-orange)](https://aws.amazon.com)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://python.org)
[![Node](https://img.shields.io/badge/Node.js-18+-green)](https://nodejs.org)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

## 목표

이 템플릿은 다음을 위해 만들어졌습니다:

- **코드 관리**: 체계적이고 표준화된 구조
- **팀 협업**: 새로운 팀원도 쉽게 이해하고 유지보수 가능
- **자동화**: 스크립트 하나로 전체 스택 배포

## 30초 시작 가이드

### 사전 요구사항

```bash
# 필수 도구 확인
node --version      # v18 이상
python3 --version   # 3.11 이상
aws --version       # AWS CLI 설치됨

# AWS 계정 설정
aws configure
```

### 원클릭 설치 & 배포

```bash
# 자동 설정 스크립트 실행
./setup.sh

# 또는 수동으로:
./setup.sh dev my-project us-east-1
```

**완료!** 모든 것이 자동으로 설정됩니다.

## 고급 사용자를 위한 메뉴 시스템

```bash
# 단계별 설정이 필요한 경우
./start.sh
```

## 프로젝트 구조

```
nexus-v2/title/
├── quick-start.sh           # 초보자용 원클릭 설치 스크립트
├── start.sh                 # 대화형 메뉴 시스템 (단계별 선택 가능)
├── 1-setup/                 # 초기 설정 스크립트
│   ├── configure.sh         # 대화형 서비스 설정
│   └── setup.sh            # 기본 설정
├── 2-infrastructure/        # AWS 인프라 생성 스크립트
│   ├── create-infrastructure.sh  # 전체 인프라 생성
│   ├── create-lambda.sh         # Lambda 함수 생성
│   ├── create-api-gateway.sh    # API Gateway 생성
│   ├── create-cognito.sh        # Cognito 사용자 풀 생성
│   └── create-cloudfront.sh     # CloudFront CDN 생성
├── 3-deploy/               # 배포 스크립트
│   ├── deploy.sh           # 스마트 배포 (변경사항 감지)
│   ├── deploy-frontend.sh  # 프론트엔드 배포
│   └── deploy-backend.sh   # 백엔드 배포
├── 4-utilities/            # 유틸리티 도구
│   └── generate-env.sh     # 환경 변수 파일 생성
├── frontend/               # React 프론트엔드
│   └── src/
│       ├── features/       # 기능별 모듈
│       │   ├── auth/       # 로그인/회원가입
│       │   ├── chat/       # AI 채팅 기능
│       │   ├── dashboard/  # 대시보드
│       │   └── landing/    # 랜딩 페이지
│       └── shared/         # 공통 컴포넌트
└── backend/                # Python Lambda 백엔드
    └── handlers/
        ├── api/            # REST API 핸들러
        │   ├── prompt.py   # 프롬프트 관리
        │   ├── usage.py    # 사용량 추적
        │   └── conversation.py # 대화 관리
        └── websocket/      # WebSocket 핸들러
            ├── connect.py     # 연결 처리
            ├── disconnect.py  # 연결 해제
            └── message.py     # 메시지 스트리밍
```

### AWS 리소스 매핑

| 폴더/파일                     | AWS 리소스       | 설명           |
| ----------------------------- | ---------------- | -------------- |
| backend/handlers/api/\*       | Lambda Functions | REST API 처리  |
| backend/handlers/websocket/\* | Lambda Functions | 실시간 통신    |
| frontend/dist/\*              | S3 Bucket        | 정적 웹 호스팅 |
| -                             | CloudFront       | CDN 배포       |
| -                             | API Gateway      | API 엔드포인트 |
| -                             | Cognito          | 사용자 인증    |
| -                             | DynamoDB         | 데이터 저장    |

## 사용 방법

### 1단계: 서비스 설정

```bash
./start.sh
# 메뉴에서 "1) 새 서비스 설정 시작" 선택
```

### 2단계: AWS 인프라 구축

```bash
# start.sh 메뉴에서 "2) AWS 인프라 구축" 선택
# "전체 인프라 한번에 구축" 선택 (권장)
```

### 3단계: 서비스 배포

```bash
# start.sh 메뉴에서 "3) 서비스 배포" 선택
# "전체 배포" 선택
```

## 필수 요구사항

- **AWS CLI**: 설치 및 인증 완료
  ```bash
  aws configure
  ```
- **Node.js**: 18.0 이상
- **Python**: 3.9 이상
- **AWS 권한**: Lambda, API Gateway, S3, DynamoDB, Cognito 생성 권한

## 보안 주의사항

**GitHub에 코드를 업로드하기 전 반드시 확인해야 할 사항:**

커밋 금지 파일:

- `.env` 파일 (실제 API 키와 비밀번호 포함)
- `config.json` 파일 (실제 설정 포함)
- AWS 자격 증명 파일

커밋 가능한 파일:

- `.env.template` 파일 (템플릿만 포함)
- `config.template.json` 파일 (템플릿만 포함)

자세한 보안 설정은 [DEPLOYMENT.md](DEPLOYMENT.md) 참조

## 환경 변수 설정

서비스 구성 시 자동으로 생성되는 파일들:

- `.env.deploy`: 메인 배포 설정
- `frontend/.env`: 프론트엔드 환경 변수
- `backend/.env`: 백엔드 환경 변수

## 개별 스크립트 실행

메뉴 시스템을 사용하지 않고 직접 스크립트를 실행할 수도 있습니다:

```bash
# 1. 서비스 설정
./1-setup/configure.sh

# 2. 인프라 생성
./2-infrastructure/create-infrastructure.sh

# 3. 배포
./3-deploy/deploy.sh
```

## 문제 해결

### AWS CLI 경로 오류

```bash
export PATH="/opt/homebrew/bin:$PATH"
```

### 권한 오류

```bash
chmod +x start.sh
chmod +x 1-setup/*.sh
chmod +x 2-infrastructure/*.sh
chmod +x 3-deploy/*.sh
chmod +x 4-utilities/*.sh
```

### 배포 실패 시

1. AWS 인증 확인: `aws sts get-caller-identity`
2. 환경 변수 파일 확인: `.env.deploy`, `frontend/.env`, `backend/.env`
3. AWS 리소스 상태 확인: start.sh 메뉴에서 "인프라 상태 확인" 선택

## AWS 리소스 상세

템플릿이 생성하는 AWS 리소스:

- **Lambda Functions** (6개)

  - api-prompt: 프롬프트 처리
  - api-usage: 사용량 관리
  - api-conversation: 대화 관리
  - ws-connect: WebSocket 연결
  - ws-disconnect: WebSocket 종료
  - ws-message: WebSocket 메시지 처리

- **DynamoDB Tables** (6개)

  - conversations: 대화 내역
  - prompts: 프롬프트 저장
  - usage: 사용량 추적
  - websocket-connections: WebSocket 연결 관리
  - files: 파일 업로드 관리
  - messages: 메시지 저장

- **API Gateway**

  - REST API: HTTP 요청 처리
  - WebSocket API: 실시간 통신

- **Cognito**

  - User Pool: 사용자 인증
  - App Client: 애플리케이션 인증

- **S3 Bucket**

  - 프론트엔드 정적 파일 호스팅

- **CloudFront**
  - CDN 배포 (HTTPS 지원)

## 커스터마이징

### 프론트엔드 수정

- `frontend/src/features/`: 새 기능 추가
- `frontend/src/`: React 컴포넌트
- `frontend/public/images/`: 로고 및 이미지 변경

### 백엔드 수정

- `backend/handlers/`: Lambda 핸들러 (API 로직)
- `backend/services/`: 비즈니스 로직

### 프롬프트 수정

- `backend/handlers/api/prompt.py`: 기본 프롬프트 설정

### 커스터마이징 포인트

- 회사 브랜딩: 로고, 색상, 폰트
- AI 모델 설정: 프롬프트, 파라미터
- 기능 추가: 새 페이지, API 엔드포인트
- 인증 설정: SSO, MFA

## 지원 및 도움말

문제가 있거나 도움이 필요한 경우:

1. README.md 파일 확인
2. start.sh 메뉴에서 "도움말" 선택
3. 로그 파일 확인: `deployment-info.txt`

## 프로덕션 배포 주의사항

- 프로덕션용 AWS 계정은 별도로 사용
- IAM 권한을 최소한으로 설정
- CloudWatch로 비용 및 사용량 모니터링
- 정기적인 보안 업데이트 적용

## 라이선스

이 템플릿은 내부 사용 목적으로 제작되었습니다.
