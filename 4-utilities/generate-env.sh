#!/bin/bash

# NEXUS TEMPLATE - 환경변수 자동 생성 스크립트
# .env.deploy에서 실제 .env 파일들을 생성

set -e

# AWS CLI 경로 설정
export PATH="/opt/homebrew/bin:$PATH"

echo "========================================="
echo "   🔧 환경변수 파일 생성"
echo "========================================="
echo ""

# .env.deploy 파일 확인
if [ ! -f ".env.deploy" ]; then
    echo "❌ .env.deploy 파일이 없습니다."
    echo "먼저 ./configure.sh를 실행하세요."
    exit 1
fi

# 환경변수 로드
source .env.deploy

echo "📋 설정 정보:"
echo "   서비스: ${SERVICE_NAME}"
echo "   환경: ${STACK_SUFFIX}"
echo "   리전: ${AWS_REGION}"
echo ""

# frontend/.env 생성
echo "📝 frontend/.env 생성 중..."
cat > frontend/.env <<EOF
# NEXUS SERVICE CONFIGURATION - ${SERVICE_NAME}
# Generated: $(date)
# Environment: ${ENVIRONMENT}

# API 설정
VITE_API_BASE_URL=https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
VITE_WS_URL=wss://${WEBSOCKET_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}

# AWS API Gateway - 서비스 엔드포인트
VITE_API_URL=https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
VITE_PROMPT_API_URL=https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
VITE_WEBSOCKET_URL=wss://${WEBSOCKET_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
VITE_USAGE_API_URL=https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
VITE_CONVERSATION_API_URL=https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
VITE_REST_API_URL=https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}

# AWS Cognito 설정
VITE_AWS_REGION=${AWS_REGION}
VITE_COGNITO_USER_POOL_ID=${COGNITO_USER_POOL_ID}
VITE_COGNITO_CLIENT_ID=${COGNITO_CLIENT_ID}

# PDF.js CDN
VITE_PDFJS_CDN_URL=https://cdnjs.cloudflare.com/ajax/libs/pdf.js

# 개발/테스트 설정
VITE_USE_MOCK=false

# Service Type
VITE_SERVICE_TYPE=${STACK_SUFFIX}

# Organization Settings
VITE_ADMIN_EMAIL=${ADMIN_EMAIL}
VITE_COMPANY_DOMAIN=${COMPANY_DOMAIN}
EOF

echo "✅ frontend/.env 생성 완료"

# backend/.env 생성
echo "📝 backend/.env 생성 중..."
cat > backend/.env <<EOF
# NEXUS SERVICE CONFIGURATION - ${SERVICE_NAME}
# Generated: $(date)
# Environment: ${ENVIRONMENT}

# AWS 설정
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}

# DynamoDB 테이블
CONVERSATIONS_TABLE=${SERVICE_NAME}-conversations-${STACK_SUFFIX}
PROMPTS_TABLE=${SERVICE_NAME}-prompts-${STACK_SUFFIX}
USAGE_TABLE=${SERVICE_NAME}-usage-${STACK_SUFFIX}
WEBSOCKET_TABLE=${SERVICE_NAME}-websocket-connections-${STACK_SUFFIX}
CONNECTIONS_TABLE=${SERVICE_NAME}-websocket-connections-${STACK_SUFFIX}
FILES_TABLE=${SERVICE_NAME}-files-${STACK_SUFFIX}
MESSAGES_TABLE=${SERVICE_NAME}-messages-${STACK_SUFFIX}

# API Gateway
REST_API_URL=https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
WEBSOCKET_API_URL=wss://${WEBSOCKET_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}
WEBSOCKET_API_ID=${WEBSOCKET_API_ID}
API_STAGE=${API_STAGE}

# Lambda 설정
LAMBDA_TIMEOUT=120
LAMBDA_MEMORY=1024
LOG_LEVEL=INFO

# Bedrock 설정
BEDROCK_MODEL_ID=us.anthropic.claude-sonnet-4-20250514-v1:0
BEDROCK_OPUS_MODEL_ID=us.anthropic.claude-opus-4-1-20250805-v1:0
BEDROCK_MAX_TOKENS=16384
BEDROCK_TEMPERATURE=0.7
BEDROCK_TOP_P=0.9
BEDROCK_TOP_K=40
ANTHROPIC_VERSION=bedrock-2023-05-31

# 가드레일 설정
GUARDRAIL_ID=${GUARDRAIL_ID}
GUARDRAIL_VERSION=1
GUARDRAIL_ENABLED=${GUARDRAIL_ENABLED}

# CloudWatch
CLOUDWATCH_NAMESPACE=${SERVICE_NAME}-${STACK_SUFFIX}
LOG_GROUP=/aws/lambda/${SERVICE_NAME}-${STACK_SUFFIX}
METRICS_ENABLED=true

# 뉴스 검색 활성화
ENABLE_NEWS_SEARCH=${ENABLE_NEWS_SEARCH}

# 엔진 타입
DEFAULT_ENGINE_TYPE=11
SECONDARY_ENGINE_TYPE=22
AVAILABLE_ENGINES=11,22,33

# 서비스 정보
SERVICE_NAME=${SERVICE_NAME}
STACK_SUFFIX=${STACK_SUFFIX}
ENVIRONMENT=${ENVIRONMENT}
EOF

echo "✅ backend/.env 생성 완료"

# .env.production 생성 (프론트엔드용)
echo "📝 frontend/.env.production 생성 중..."
cp frontend/.env frontend/.env.production
echo "✅ frontend/.env.production 생성 완료"

echo ""
echo "========================================="
echo "   ✅ 환경변수 파일 생성 완료"
echo "========================================="
echo ""
echo "생성된 파일:"
echo "   - frontend/.env"
echo "   - frontend/.env.production"
echo "   - backend/.env"
echo ""
echo "API 엔드포인트:"
echo "   REST API: https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}"
if [ ! -z "${WEBSOCKET_API_ID}" ]; then
    echo "   WebSocket: wss://${WEBSOCKET_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}"
fi
echo ""
echo "💡 다음 단계:"
echo "   1. 프론트엔드 배포: ./deploy-frontend.sh"
echo "   2. 백엔드 배포: ./deploy-backend.sh"
echo ""