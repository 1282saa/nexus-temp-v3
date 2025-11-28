# Nexus 프로젝트 컨텍스트 문서

## 프로젝트 개요

### 목적

AI 채팅 서비스를 AWS에 빠르게 배포할 수 있는 템플릿 시스템

### 대상 사용자

- 비개발자: 원클릭 설치 스크립트 제공
- 개발자: 커스터마이징 가능한 모듈형 구조

### 핵심 기능

- 실시간 AI 채팅 (WebSocket 스트리밍)
- 사용자 인증 (AWS Cognito)
- 대화 기록 저장 및 관리
- 사용량 추적 및 제한
- 프롬프트 템플릿 관리

## 기술 스택

### Frontend

- React 18 + Vite (빌드 도구)
- Tailwind CSS (스타일링)
- AWS Amplify SDK (인증)
- WebSocket (실시간 통신)

### Backend

- Python 3.11 (Lambda 런타임)
- Serverless Framework (배포 관리)
- boto3 (AWS SDK)
- WebSocket API (실시간 스트리밍)

### AWS 인프라

- Lambda Functions (6개): API 및 WebSocket 핸들러
- DynamoDB Tables (6개): 데이터 저장
- API Gateway: REST API + WebSocket API
- S3 + CloudFront: 정적 웹 호스팅
- Cognito: 사용자 인증 및 관리

### AI 모델

- Amazon Bedrock (Claude 3.5 Sonnet)

## 배포 작업 흐름

### 자동 배포 (비개발자용)

1. AWS CLI 설치 및 인증 설정
2. `quick-start.sh` 실행
3. 자동으로 모든 AWS 리소스 생성
4. 프론트엔드/백엔드 자동 배포
5. CloudFront URL 생성 및 접속 가능

### 수동 배포 (개발자용)

1. 환경 설정: `1-setup/configure.sh`
2. 인프라 생성: `2-infrastructure/create-infrastructure.sh`
3. 코드 배포: `3-deploy/deploy.sh`
4. 환경 변수 확인 및 테스트

## 프로젝트 구조

### 배포 스크립트

- `1-setup/`: 초기 환경 설정
- `2-infrastructure/`: AWS 리소스 생성
- `3-deploy/`: 코드 배포 및 업데이트
- `4-utilities/`: 유틸리티 도구

### 소스 코드

- `frontend/src/features/`: React 기능 모듈
- `backend/handlers/api/`: REST API 핸들러
- `backend/handlers/websocket/`: WebSocket 핸들러
- `backend/services/`: 비즈니스 로직 서비스

### 설정 파일

- `.env.template`: 환경 변수 템플릿
- `config.template.json`: 서비스 설정 템플릿
- `serverless.yml`: 백엔드 배포 설정

## 개발 및 배포 시 주의사항

### 필수 사전 요구사항

- Node.js 18.0 이상
- Python 3.11
- AWS CLI 설치 및 인증 완료
- AWS 계정 및 적절한 권한

### 보안 관련

- 절대 .env 파일을 Git에 커밋하지 않음
- AWS 자격 증명을 코드에 하드코딩하지 않음
- Cognito User Pool ID와 Client ID는 환경 변수로 관리
- 프로덕션 환경에서는 별도의 AWS 계정 사용 권장

### 스크립트 실행

- 모든 스크립트는 bash 기반 (Mac/Linux)
- Windows 사용자는 WSL 또는 Git Bash 사용
- 스크립트 실행 전 항상 AWS CLI 인증 확인
- 에러 발생 시 즉시 중단 (set -e 적용)

### 비용 관련

- Lambda: 매월 100만 요청 무료
- DynamoDB: 온디맨드 요금제 (사용한 만큼 지불)
- S3 + CloudFront: 트래픽에 따라 과금
- Cognito: 월 50,000 MAU까지 무료
