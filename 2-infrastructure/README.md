# 📁 2-infrastructure/ - AWS 인프라 생성

이 폴더는 AWS 클라우드 인프라를 생성하고 구성하는 스크립트들을 포함합니다.

## 📌 주요 기능
- AWS 서버리스 인프라 자동 생성
- Lambda, API Gateway, DynamoDB 등 리소스 프로비저닝
- 보안 및 권한 설정

## 📄 포함된 파일

### create-infrastructure.sh
- **목적**: 통합 인프라 생성 (원스톱 실행)
- **기능**:
  - 모든 인프라 구성 요소를 순서대로 생성
  - DynamoDB 테이블 6개 생성
  - S3 버킷 생성
  - --auto 플래그로 자동 실행 지원
- **생성 리소스**: DynamoDB, S3

### create-lambda.sh
- **목적**: Lambda 함수 6개 생성
- **기능**:
  - IAM 실행 역할 생성 및 정책 연결
  - REST API용 Lambda 3개 (conversation, prompt, usage)
  - WebSocket용 Lambda 3개 (connect, disconnect, message)
  - Bedrock AI 접근 권한 설정
- **생성 리소스**: Lambda Functions, IAM Role

### create-api-gateway.sh
- **목적**: API Gateway 생성 및 구성
- **기능**:
  - REST API 생성 및 엔드포인트 설정
  - WebSocket API 생성 및 라우트 구성
  - Lambda 함수 연결
  - CORS 설정
- **생성 리소스**: REST API, WebSocket API

### create-cognito.sh
- **목적**: 사용자 인증 시스템 구성
- **기능**:
  - Cognito User Pool 생성
  - App Client 설정
  - 인증 정책 구성
  - 이메일/비밀번호 로그인 활성화
- **생성 리소스**: Cognito User Pool, App Client

### create-cloudfront.sh
- **목적**: CDN 배포 설정
- **기능**:
  - CloudFront Distribution 생성
  - S3 버킷과 연결
  - 캐싱 정책 설정
  - HTTPS 활성화
- **생성 리소스**: CloudFront Distribution

## 🔧 사용 방법

```bash
# 전체 인프라 한 번에 생성 (권장)
bash 2-infrastructure/create-infrastructure.sh

# 자동 모드로 실행
bash 2-infrastructure/create-infrastructure.sh --auto

# 개별 리소스 생성
bash 2-infrastructure/create-lambda.sh
bash 2-infrastructure/create-api-gateway.sh
bash 2-infrastructure/create-cognito.sh
bash 2-infrastructure/create-cloudfront.sh
```

## 📊 생성되는 AWS 리소스

| 서비스 | 리소스 수 | 용도 |
|--------|-----------|------|
| DynamoDB | 6개 테이블 | 데이터 저장 |
| Lambda | 6개 함수 | 비즈니스 로직 |
| API Gateway | 2개 (REST, WebSocket) | API 엔드포인트 |
| S3 | 1개 버킷 | 정적 파일 호스팅 |
| Cognito | 1개 User Pool | 사용자 인증 |
| CloudFront | 1개 Distribution | CDN |
| IAM | 1개 Role | Lambda 실행 권한 |

## ⚠️ 주의사항
- AWS 비용이 발생할 수 있음
- 리소스 이름 충돌 방지를 위해 고유한 서비스명 사용
- 삭제 시 역순으로 진행 권장