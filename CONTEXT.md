# AI 도구 사용 시 컨텍스트

## 프로젝트 개요
- **목적**: AI 채팅 서비스 템플릿 시스템
- **대상**: 비개발자도 사용 가능한 원클릭 배포
- **스택**: React + Python Lambda + AWS Serverless

## 기술 스택
- **Frontend**: React, Vite, Tailwind CSS, AWS SDK
- **Backend**: Python 3.9, boto3, AWS Lambda
- **Infrastructure**: DynamoDB, S3, CloudFront, API Gateway, Cognito
- **AI**: Amazon Bedrock (Claude)

## 현재 작업 흐름
1. `quick-start.sh` 실행
2. 자동으로 AWS 인프라 생성
3. 프론트엔드/백엔드 자동 배포
4. CloudFront URL로 서비스 접속

## 주요 경로
- 스크립트: `1-setup/`, `2-infrastructure/`, `3-deploy/`
- 프론트엔드 소스: `frontend/src/features/`
- 백엔드 핸들러: `backend/handlers/`
- 환경 설정: `.env.deploy`, `frontend/.env`, `backend/.env`

## 작업 시 참고사항
- 모든 스크립트는 bash 기반
- AWS CLI 인증 필수
- 민감 정보는 .gitignore에 포함
- 에러 처리: set -e 사용