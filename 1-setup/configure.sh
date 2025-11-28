#!/bin/bash

# NEXUS TEMPLATE - 설정 스크립트
# 템플릿 버전: 2.0.0
# 이 스크립트는 사용자 입력을 받아 환경변수 파일을 생성합니다

set -e

echo "========================================="
echo "   🚀 NEXUS TEMPLATE 설정 마법사"
echo "========================================="
echo ""
echo "서비스 설정을 시작합니다..."
echo ""

# 기본값 설정
DEFAULT_REGION="us-east-1"
DEFAULT_STAGE="prod"
DEFAULT_ENV="production"

# config.json 파일 확인
if [ -f "config.json" ]; then
    echo "✅ 기존 설정 파일(config.json)을 발견했습니다."
    read -p "기존 설정을 불러오시겠습니까? (y/n): " LOAD_CONFIG
    
    if [ "$LOAD_CONFIG" = "y" ] || [ "$LOAD_CONFIG" = "Y" ]; then
        # JSON 파싱 (jq가 있는 경우)
        if command -v jq &> /dev/null; then
            SERVICE_NAME=$(jq -r '.service.serviceName' config.json)
            STACK_SUFFIX=$(jq -r '.service.stackSuffix' config.json)
            ENVIRONMENT=$(jq -r '.service.environment' config.json)
            CUSTOM_DOMAIN=$(jq -r '.service.customDomain' config.json)
            AWS_REGION=$(jq -r '.aws.region' config.json)
            AWS_ACCOUNT_ID=$(jq -r '.aws.accountId' config.json)
            ADMIN_EMAIL=$(jq -r '.admin.email' config.json)
            COMPANY_DOMAIN=$(jq -r '.admin.companyDomain' config.json)
            echo "✅ 설정을 불러왔습니다."
            echo ""
        else
            echo "⚠️  jq가 설치되어 있지 않아 설정을 불러올 수 없습니다."
            echo "새로운 설정을 입력해주세요."
            echo ""
        fi
    fi
fi

# 사용자 입력 받기
echo "📋 서비스 기본 정보"
echo "-------------------"

if [ -z "$SERVICE_NAME" ]; then
    read -p "1. 서비스 이름 (예: my-app): " SERVICE_NAME
    SERVICE_NAME=${SERVICE_NAME:-my-app}
fi

if [ -z "$STACK_SUFFIX" ]; then
    read -p "2. 스택 접미사 (예: prod, dev, staging): " STACK_SUFFIX
    STACK_SUFFIX=${STACK_SUFFIX:-prod}
fi

if [ -z "$ENVIRONMENT" ]; then
    echo "3. 환경 선택:"
    echo "   1) production"
    echo "   2) development"
    echo "   3) staging"
    read -p "선택 (1-3): " ENV_CHOICE
    case $ENV_CHOICE in
        1) ENVIRONMENT="production" ;;
        2) ENVIRONMENT="development" ;;
        3) ENVIRONMENT="staging" ;;
        *) ENVIRONMENT="production" ;;
    esac
fi

if [ -z "$CUSTOM_DOMAIN" ]; then
    read -p "4. 커스텀 도메인 (옵션, 예: app.example.com): " CUSTOM_DOMAIN
fi

echo ""
echo "📋 AWS 설정"
echo "-----------"

if [ -z "$AWS_REGION" ]; then
    read -p "5. AWS 리전 (기본: us-east-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-$DEFAULT_REGION}
fi

if [ -z "$AWS_ACCOUNT_ID" ]; then
    # AWS 계정 ID 자동 감지 시도
    AUTO_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    if [ -n "$AUTO_ACCOUNT_ID" ]; then
        echo "✅ AWS 계정 ID 자동 감지: $AUTO_ACCOUNT_ID"
        read -p "이 계정을 사용하시겠습니까? (Y/n): " USE_AUTO
        if [ "$USE_AUTO" != "n" ] && [ "$USE_AUTO" != "N" ]; then
            AWS_ACCOUNT_ID=$AUTO_ACCOUNT_ID
        fi
    fi
    
    # 자동 감지 실패 또는 사용자가 거부한 경우 수동 입력
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        read -p "6. AWS 계정 ID (12자리 숫자): " AWS_ACCOUNT_ID
        while [ ${#AWS_ACCOUNT_ID} -ne 12 ]; do
            echo "❌ AWS 계정 ID는 12자리여야 합니다."
            read -p "다시 입력해주세요: " AWS_ACCOUNT_ID
        done
    fi
fi

echo ""
echo "📋 관리자 설정"
echo "--------------"

if [ -z "$ADMIN_EMAIL" ]; then
    read -p "7. 관리자 이메일: " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
fi

if [ -z "$COMPANY_DOMAIN" ]; then
    read -p "8. 회사 도메인 (예: @example.com): " COMPANY_DOMAIN
    if [ ! -z "$COMPANY_DOMAIN" ] && [[ ! "$COMPANY_DOMAIN" == @* ]]; then
        COMPANY_DOMAIN="@$COMPANY_DOMAIN"
    fi
fi

echo ""
echo "📋 고급 설정"
echo "------------"

read -p "9. 뉴스 검색 기능 활성화? (y/n): " ENABLE_NEWS
if [ "$ENABLE_NEWS" = "y" ] || [ "$ENABLE_NEWS" = "Y" ]; then
    ENABLE_NEWS_SEARCH="true"
else
    ENABLE_NEWS_SEARCH="false"
fi

read -p "10. Guardrails 활성화? (y/n): " ENABLE_GUARD
if [ "$ENABLE_GUARD" = "y" ] || [ "$ENABLE_GUARD" = "Y" ]; then
    GUARDRAIL_ENABLED="true"
    read -p "    Guardrail ID 입력: " GUARDRAIL_ID
else
    GUARDRAIL_ENABLED="false"
    GUARDRAIL_ID=""
fi

# 자동 생성 값들
S3_BUCKET="${SERVICE_NAME}-${STACK_SUFFIX}-frontend"
CLOUDWATCH_NAMESPACE="${SERVICE_NAME}-${STACK_SUFFIX}"
API_STAGE=${DEFAULT_STAGE}
SERVICE_TYPE=${STACK_SUFFIX}

echo ""
echo "========================================="
echo "   📋 설정 확인"
echo "========================================="
echo ""
echo "서비스 이름: ${SERVICE_NAME}"
echo "스택 접미사: ${STACK_SUFFIX}"
echo "환경: ${ENVIRONMENT}"
echo "도메인: ${CUSTOM_DOMAIN:-없음}"
echo "AWS 리전: ${AWS_REGION}"
echo "AWS 계정: ${AWS_ACCOUNT_ID}"
echo "관리자 이메일: ${ADMIN_EMAIL}"
echo "회사 도메인: ${COMPANY_DOMAIN:-없음}"
echo "뉴스 검색: ${ENABLE_NEWS_SEARCH}"
echo "Guardrails: ${GUARDRAIL_ENABLED}"
echo ""

read -p "이 설정으로 진행하시겠습니까? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ 설정이 취소되었습니다."
    exit 1
fi

# config.json 생성
echo ""
echo "📝 config.json 생성 중..."
cat > config.json <<EOF
{
  "project": {
    "name": "nexus-template",
    "version": "2.0.0",
    "description": "AI-powered chat application"
  },
  "service": {
    "serviceName": "${SERVICE_NAME}",
    "stackSuffix": "${STACK_SUFFIX}",
    "environment": "${ENVIRONMENT}",
    "customDomain": "${CUSTOM_DOMAIN}",
    "serviceType": "${SERVICE_TYPE}"
  },
  "aws": {
    "region": "${AWS_REGION}",
    "accountId": "${AWS_ACCOUNT_ID}",
    "profile": "default",
    "apiStage": "${API_STAGE}"
  },
  "infrastructure": {
    "s3Bucket": "${S3_BUCKET}",
    "cloudfrontId": "",
    "cloudfrontDomain": "",
    "restApiId": "",
    "websocketApiId": ""
  },
  "cognito": {
    "userPoolId": "",
    "clientId": ""
  },
  "admin": {
    "email": "${ADMIN_EMAIL}",
    "companyDomain": "${COMPANY_DOMAIN}"
  },
  "features": {
    "enableNewsSearch": ${ENABLE_NEWS_SEARCH},
    "enableFileUpload": true,
    "maxFileSizeMB": 10,
    "sessionTimeoutMinutes": 30,
    "enableGuardrails": ${GUARDRAIL_ENABLED}
  },
  "bedrock": {
    "modelId": "us.anthropic.claude-sonnet-4-20250514-v1:0",
    "opusModelId": "us.anthropic.claude-opus-4-1-20250805-v1:0",
    "maxTokens": 16384,
    "temperature": 0.7,
    "topP": 0.9,
    "topK": 40
  },
  "monitoring": {
    "metricsEnabled": true,
    "logLevel": "INFO",
    "cloudwatchNamespace": "${CLOUDWATCH_NAMESPACE}",
    "logGroupPrefix": "/aws/lambda/"
  }
}
EOF

# .env.deploy 생성 (배포 스크립트용)
echo "📝 .env.deploy 생성 중..."

# 기존 .env.deploy가 있으면 백업
if [ -f ".env.deploy" ]; then
    cp .env.deploy .env.deploy.backup.$(date +%Y%m%d_%H%M%S)
fi

# 템플릿에서 생성
cat > .env.deploy <<EOF
# 배포 설정
# 생성일: $(date)

# 서비스 정보
SERVICE_NAME=${SERVICE_NAME}
STACK_SUFFIX=${STACK_SUFFIX}
ENVIRONMENT=${ENVIRONMENT}
CUSTOM_DOMAIN=${CUSTOM_DOMAIN}
SERVICE_TYPE=${SERVICE_TYPE}

# AWS 설정
AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
API_STAGE=${API_STAGE}

# 인프라 (인프라 생성 후 자동 업데이트)
S3_BUCKET=${S3_BUCKET}
CLOUDFRONT_ID=
CLOUDFRONT_DOMAIN=
REST_API_ID=
WEBSOCKET_API_ID=

# Cognito (인프라 생성 후 자동 업데이트)
COGNITO_USER_POOL_ID=
COGNITO_CLIENT_ID=

# 관리자
ADMIN_EMAIL=${ADMIN_EMAIL}
COMPANY_DOMAIN=${COMPANY_DOMAIN}

# 기능
ENABLE_NEWS_SEARCH=${ENABLE_NEWS_SEARCH}
GUARDRAIL_ENABLED=${GUARDRAIL_ENABLED}
GUARDRAIL_ID=${GUARDRAIL_ID}

# 환경변수 업데이트 옵션
UPDATE_ENV_VARS=false
EOF

echo "✅ 설정 파일 생성 완료"
echo ""
echo "========================================="
echo "   ✨ 설정 완료!"
echo "========================================="
echo ""
echo "생성된 파일:"
echo "  - config.json: 프로젝트 설정"
echo "  - .env.deploy: 배포 스크립트용 환경변수"
echo ""
echo "다음 단계:"
echo "  1. AWS 인프라 생성: ./scripts-v2/deploy-infrastructure.sh"
echo "  2. 프론트엔드 배포: ./deploy-frontend.sh"
echo "  3. 백엔드 배포: ./deploy-backend.sh"
echo ""
echo "💡 인프라 생성 후 .env.deploy 파일의 ID들이 자동 업데이트됩니다."
echo ""