#!/bin/bash

# NEXUS TEMPLATE - 통합 인프라 생성 스크립트
# 템플릿 버전: 2.0.0
# 모든 AWS 리소스를 순서대로 생성

set -e

# 진행 상황 저장 함수
mark_complete() {
    mkdir -p .nexus-state
    touch ".nexus-state/$1.done"
    echo "✅ $1 완료 상태 저장됨"
}

check_complete() {
    [ -f ".nexus-state/$1.done" ]
}

echo "========================================="
echo "   🏗️ NEXUS TEMPLATE 인프라 구축"
echo "========================================="
echo ""

# 환경변수 확인
if [ ! -f ".env.deploy" ]; then
    echo "❌ .env.deploy 파일이 없습니다."
    echo "먼저 ./configure.sh를 실행하여 설정을 완료하세요."
    exit 1
fi

source .env.deploy

echo "📋 구축할 인프라:"
echo "   서비스: ${SERVICE_NAME}"
echo "   환경: ${STACK_SUFFIX}"
echo "   리전: ${AWS_REGION}"
echo ""
echo "생성될 리소스:"
echo "   - DynamoDB 테이블 (6개)"
echo "   - S3 버킷 (1개)"
echo "   - Lambda 함수 (6개)"
echo "   - API Gateway (REST + WebSocket)"
echo "   - Cognito User Pool"
echo ""

# 자동 모드 체크 (quick-start.sh에서 호출된 경우)
if [ "$1" != "--auto" ]; then
    read -p "계속하시겠습니까? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "❌ 취소되었습니다."
        exit 0
    fi
fi

echo ""
echo "========================================="
echo "   Step 1/6: DynamoDB 테이블 생성"
echo "========================================="

# DynamoDB 테이블 생성
TABLES=(
    "${SERVICE_NAME}-conversations-${STACK_SUFFIX}"
    "${SERVICE_NAME}-prompts-${STACK_SUFFIX}"
    "${SERVICE_NAME}-usage-${STACK_SUFFIX}"
    "${SERVICE_NAME}-websocket-connections-${STACK_SUFFIX}"
    "${SERVICE_NAME}-files-${STACK_SUFFIX}"
    "${SERVICE_NAME}-messages-${STACK_SUFFIX}"
)

for TABLE in "${TABLES[@]}"; do
    if aws dynamodb describe-table --table-name $TABLE --region $AWS_REGION >/dev/null 2>&1; then
        echo "   ✅ $TABLE (이미 존재함)"
    else
        echo "   🔄 $TABLE 생성 중..."
        aws dynamodb create-table \
            --table-name $TABLE \
            --attribute-definitions AttributeName=id,AttributeType=S \
            --key-schema AttributeName=id,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region $AWS_REGION \
            --output text > /dev/null
        echo "      ✅ 완료"
    fi
done

echo ""
echo "========================================="
echo "   Step 2/6: S3 버킷 생성"
echo "========================================="

if aws s3api head-bucket --bucket $S3_BUCKET --region $AWS_REGION 2>/dev/null; then
    echo "   ✅ $S3_BUCKET (이미 존재함)"
else
    echo "   🔄 $S3_BUCKET 생성 중..."
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket $S3_BUCKET --region $AWS_REGION
    else
        aws s3api create-bucket --bucket $S3_BUCKET \
            --region $AWS_REGION \
            --create-bucket-configuration LocationConstraint=$AWS_REGION
    fi
    
    # 정적 웹사이트 호스팅 설정
    aws s3 website s3://$S3_BUCKET/ \
        --index-document index.html \
        --error-document error.html
    
    # 퍼블릭 액세스 차단 해제 (정적 웹사이트용)
    aws s3api put-public-access-block \
        --bucket $S3_BUCKET \
        --public-access-block-configuration \
        "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
        --region $AWS_REGION 2>/dev/null || true
    
    # 버킷 정책 설정
    cat > /tmp/bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${S3_BUCKET}/*"
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy \
        --bucket $S3_BUCKET \
        --policy file:///tmp/bucket-policy.json \
        --region $AWS_REGION 2>/dev/null || true
    
    rm -f /tmp/bucket-policy.json
    echo "      ✅ 완료"
fi

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "========================================="
echo "   Step 3/6: Lambda 함수 생성"
echo "========================================="

# Lambda 생성 스크립트 실행
if [ -f "${SCRIPT_DIR}/create-lambda.sh" ]; then
    bash "${SCRIPT_DIR}/create-lambda.sh"
else
    echo "   ⚠️  Lambda 생성 스크립트가 없습니다."
fi

echo ""
echo "========================================="
echo "   Step 4/6: API Gateway 생성"
echo "========================================="

# API Gateway 생성 스크립트 실행
if [ -f "${SCRIPT_DIR}/create-api-gateway.sh" ]; then
    bash "${SCRIPT_DIR}/create-api-gateway.sh"
else
    echo "   ⚠️  API Gateway 생성 스크립트가 없습니다."
fi

echo ""
echo "========================================="
echo "   Step 5/6: Cognito User Pool 생성"
echo "========================================="

# Cognito 생성 스크립트 실행
if [ -f "${SCRIPT_DIR}/create-cognito.sh" ]; then
    bash "${SCRIPT_DIR}/create-cognito.sh"
else
    echo "   ⚠️  Cognito 생성 스크립트가 없습니다."
fi

echo ""
echo "========================================="
echo "   Step 6/6: CloudFront 배포 생성"
echo "========================================="

# CloudFront 생성 스크립트 실행
if [ -f "${SCRIPT_DIR}/create-cloudfront.sh" ]; then
    bash "${SCRIPT_DIR}/create-cloudfront.sh"
else
    echo "   ⚠️  CloudFront 생성 스크립트가 없습니다."
fi

# 최종 설정 확인
echo ""
echo "========================================="
echo "   📊 인프라 구축 결과"
echo "========================================="

# 설정 파일 다시 로드 (업데이트된 값 반영)
source .env.deploy

echo ""
echo "✅ 생성된 리소스:"
echo ""
echo "📊 DynamoDB:"
for TABLE in "${TABLES[@]}"; do
    echo "   - $TABLE"
done
echo ""
echo "🪣 S3:"
echo "   - $S3_BUCKET"
echo "   - URL: http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
echo ""
echo "⚡ Lambda:"
echo "   - ${SERVICE_NAME}-conversation-api-${STACK_SUFFIX}"
echo "   - ${SERVICE_NAME}-prompt-crud-${STACK_SUFFIX}"
echo "   - ${SERVICE_NAME}-usage-handler-${STACK_SUFFIX}"
echo "   - ${SERVICE_NAME}-websocket-connect-${STACK_SUFFIX}"
echo "   - ${SERVICE_NAME}-websocket-disconnect-${STACK_SUFFIX}"
echo "   - ${SERVICE_NAME}-websocket-message-${STACK_SUFFIX}"
echo ""

if [ ! -z "${REST_API_ID}" ]; then
    echo "🌐 API Gateway:"
    echo "   - REST API: https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}"
fi

if [ ! -z "${WEBSOCKET_API_ID}" ]; then
    echo "   - WebSocket: wss://${WEBSOCKET_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}"
fi

if [ ! -z "${COGNITO_USER_POOL_ID}" ]; then
    echo ""
    echo "🔐 Cognito:"
    echo "   - User Pool ID: ${COGNITO_USER_POOL_ID}"
    echo "   - Client ID: ${COGNITO_CLIENT_ID}"
fi

echo ""
echo "========================================="
echo "   🎉 인프라 구축 완료!"
echo "========================================="
echo ""
echo "다음 단계:"
echo "   1. 프론트엔드 배포: ./deploy-frontend.sh"
echo "   2. 백엔드 코드 배포: ./deploy-backend.sh"
echo "   3. 전체 테스트: ./deploy.sh"
echo ""
echo "💡 팁:"
echo "   - 리소스 상태 확인: ./deploy.sh → 2"
echo "   - 로그 확인: aws logs tail /aws/lambda/${SERVICE_NAME}-${STACK_SUFFIX} --follow"
echo ""

# 생성 완료 마커 파일
date > .infrastructure-created