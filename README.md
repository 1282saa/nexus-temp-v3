# 🚀 Nexus - AI Chat Service Template

> **원클릭으로 배포 가능한 엔터프라이즈급 AI 채팅 서비스 템플릿**

[![AWS](https://img.shields.io/badge/AWS-Serverless-orange)](https://aws.amazon.com)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://python.org)
[![Node](https://img.shields.io/badge/Node.js-18+-green)](https://nodejs.org)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

## 🎯 목표

이 템플릿은 다음을 위해 만들어졌습니다:
- ✅ **코드 관리**: 체계적이고 표준화된 구조
- ✅ **팀 협업**: 새로운 팀원도 쉽게 이해하고 유지보수 가능
- ✅ **자동화**: 스크립트 하나로 전체 스택 배포

## 🚀 30초 시작 가이드

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
# 🎆 자동 설정 스크립트 실행
./setup.sh

# 또는 수동으로:
./setup.sh dev my-project us-east-1
```

🎉 **완료!** 모든 것이 자동으로 설정됩니다.

## 🎯 고급 사용자를 위한 메뉴 시스템

```bash
# 단계별 설정이 필요한 경우
./start.sh
```

## 📁 폴더 구조

```
nexus-v2/title/
├── quick-start.sh           # 🌟 초보자용 원클릭 설치 (가장 쉬운 방법!)
├── start.sh                 # 🎯 메인 실행 스크립트 (메뉴 시스템)
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
├── frontend/               # React 프론트엔드 코드
└── backend/                # Python Lambda 백엔드 코드
```

## 🎯 사용 방법

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

## 🔧 필수 요구사항

- **AWS CLI**: 설치 및 인증 완료
  ```bash
  aws configure
  ```
- **Node.js**: 18.0 이상
- **Python**: 3.9 이상
- **AWS 권한**: Lambda, API Gateway, S3, DynamoDB, Cognito 생성 권한

## 📝 환경 변수 설정

서비스 구성 시 자동으로 생성되는 파일들:

- `.env.deploy`: 메인 배포 설정
- `frontend/.env`: 프론트엔드 환경 변수
- `backend/.env`: 백엔드 환경 변수

## 🚀 개별 스크립트 실행

메뉴 시스템을 사용하지 않고 직접 스크립트를 실행할 수도 있습니다:

```bash
# 1. 서비스 설정
./1-setup/configure.sh

# 2. 인프라 생성
./2-infrastructure/create-infrastructure.sh

# 3. 배포
./3-deploy/deploy.sh
```

## 🔍 문제 해결

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

## 📊 AWS 리소스

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

## 🎨 커스터마이징

### 프론트엔드 수정
- `frontend/src/`: React 컴포넌트
- `frontend/public/images/`: 로고 및 이미지

### 백엔드 수정
- `backend/handlers/`: Lambda 핸들러
- `backend/services/`: 비즈니스 로직

### 프롬프트 수정
- `backend/handlers/api/prompt.py`: 기본 프롬프트 설정

## 📞 지원

문제가 있거나 도움이 필요한 경우:
1. README.md 파일 확인
2. start.sh 메뉴에서 "도움말" 선택
3. 로그 파일 확인: `deployment-info.txt`

## 🔐 보안 주의사항

- `.env` 파일들을 절대 Git에 커밋하지 마세요
- AWS 인증 정보를 코드에 하드코딩하지 마세요
- 프로덕션 환경에서는 보안 그룹과 IAM 권한을 최소화하세요

## 📄 라이선스

이 템플릿은 내부 사용 목적으로 제작되었습니다.