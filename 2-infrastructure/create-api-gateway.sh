#!/bin/bash

# NEXUS TEMPLATE - API Gateway 생성 스크립트
# 템플릿 버전: 2.0.0

set -e

# AWS CLI 경로 설정
export PATH="/opt/homebrew/bin:$PATH"

# 환경변수 로드
if [ ! -f ".env.deploy" ]; then
    echo "❌ .env.deploy 파일이 없습니다."
    exit 1
fi

source .env.deploy

echo "========================================="
echo "   🌐 API Gateway 생성"
echo "========================================="
echo ""
echo "서비스: ${SERVICE_NAME}"
echo "환경: ${STACK_SUFFIX}"
echo ""

# REST API 생성
REST_API_NAME="${SERVICE_NAME}-rest-api-${STACK_SUFFIX}"
echo "📡 REST API 생성/확인 중..."

# 기존 API 확인
EXISTING_API=$(aws apigateway get-rest-apis --region ${AWS_REGION} \
    --query "items[?name=='${REST_API_NAME}'].id" --output text 2>/dev/null || echo "")

if [ ! -z "${EXISTING_API}" ]; then
    REST_API_ID=${EXISTING_API}
    echo "   ✅ REST API 존재함: ${REST_API_ID}"
else
    echo "   🔄 REST API 생성 중..."
    REST_API_ID=$(aws apigateway create-rest-api \
        --name ${REST_API_NAME} \
        --description "REST API for ${SERVICE_NAME}" \
        --endpoint-configuration types=REGIONAL \
        --region ${AWS_REGION} \
        --query 'id' \
        --output text)
    echo "   ✅ REST API 생성 완료: ${REST_API_ID}"
fi

# Root 리소스 ID 가져오기
ROOT_ID=$(aws apigateway get-resources \
    --rest-api-id ${REST_API_ID} \
    --region ${AWS_REGION} \
    --query "items[?path=='/'].id" \
    --output text)

# API 리소스 및 메서드 생성 함수
create_api_resource() {
    local PATH=$1
    local METHOD=$2
    local LAMBDA_NAME=$3
    
    echo "   📌 ${PATH} [${METHOD}] 설정 중..."
    
    # 리소스 확인/생성
    RESOURCE_ID=$(aws apigateway get-resources \
        --rest-api-id ${REST_API_ID} \
        --region ${AWS_REGION} \
        --query "items[?pathPart=='${PATH}'].id" \
        --output text 2>/dev/null || echo "")
    
    if [ -z "${RESOURCE_ID}" ]; then
        RESOURCE_ID=$(aws apigateway create-resource \
            --rest-api-id ${REST_API_ID} \
            --parent-id ${ROOT_ID} \
            --path-part ${PATH} \
            --region ${AWS_REGION} \
            --query 'id' \
            --output text)
        echo "      ✅ 리소스 생성: /${PATH}"
    fi
    
    # 메서드 생성
    aws apigateway put-method \
        --rest-api-id ${REST_API_ID} \
        --resource-id ${RESOURCE_ID} \
        --http-method ${METHOD} \
        --authorization-type NONE \
        --region ${AWS_REGION} >/dev/null 2>&1 || true
    
    # Lambda 통합
    aws apigateway put-integration \
        --rest-api-id ${REST_API_ID} \
        --resource-id ${RESOURCE_ID} \
        --http-method ${METHOD} \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${LAMBDA_NAME}/invocations" \
        --region ${AWS_REGION} >/dev/null 2>&1 || true
    
    # Lambda 권한 부여
    aws lambda add-permission \
        --function-name ${LAMBDA_NAME} \
        --statement-id apigateway-${PATH}-${METHOD} \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:${AWS_REGION}:${AWS_ACCOUNT_ID}:${REST_API_ID}/*/*" \
        --region ${AWS_REGION} >/dev/null 2>&1 || true
    
    echo "      ✅ 완료"
}

# REST API 엔드포인트 생성
echo ""
echo "🔧 REST API 엔드포인트 설정 중..."
create_api_resource "conversations" "GET" "${SERVICE_NAME}-conversation-api-${STACK_SUFFIX}"
create_api_resource "conversations" "POST" "${SERVICE_NAME}-conversation-api-${STACK_SUFFIX}"
create_api_resource "conversations" "DELETE" "${SERVICE_NAME}-conversation-api-${STACK_SUFFIX}"
create_api_resource "prompts" "GET" "${SERVICE_NAME}-prompt-crud-${STACK_SUFFIX}"
create_api_resource "prompts" "POST" "${SERVICE_NAME}-prompt-crud-${STACK_SUFFIX}"
create_api_resource "usage" "GET" "${SERVICE_NAME}-usage-handler-${STACK_SUFFIX}"
create_api_resource "usage" "POST" "${SERVICE_NAME}-usage-handler-${STACK_SUFFIX}"

# CORS 설정
echo ""
echo "🔓 CORS 설정 중..."
for RESOURCE in conversations prompts usage; do
    RESOURCE_ID=$(aws apigateway get-resources \
        --rest-api-id ${REST_API_ID} \
        --region ${AWS_REGION} \
        --query "items[?pathPart=='${RESOURCE}'].id" \
        --output text 2>/dev/null || echo "")
    
    if [ ! -z "${RESOURCE_ID}" ]; then
        # OPTIONS 메서드 추가
        aws apigateway put-method \
            --rest-api-id ${REST_API_ID} \
            --resource-id ${RESOURCE_ID} \
            --http-method OPTIONS \
            --authorization-type NONE \
            --region ${AWS_REGION} >/dev/null 2>&1 || true
        
        # Mock 통합
        aws apigateway put-integration \
            --rest-api-id ${REST_API_ID} \
            --resource-id ${RESOURCE_ID} \
            --http-method OPTIONS \
            --type MOCK \
            --integration-http-method OPTIONS \
            --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
            --region ${AWS_REGION} >/dev/null 2>&1 || true
        
        # 응답 설정
        aws apigateway put-method-response \
            --rest-api-id ${REST_API_ID} \
            --resource-id ${RESOURCE_ID} \
            --http-method OPTIONS \
            --status-code 200 \
            --response-parameters '{"method.response.header.Access-Control-Allow-Origin":false,"method.response.header.Access-Control-Allow-Methods":false,"method.response.header.Access-Control-Allow-Headers":false}' \
            --region ${AWS_REGION} >/dev/null 2>&1 || true
        
        aws apigateway put-integration-response \
            --rest-api-id ${REST_API_ID} \
            --resource-id ${RESOURCE_ID} \
            --http-method OPTIONS \
            --status-code 200 \
            --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,DELETE,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'}' \
            --region ${AWS_REGION} >/dev/null 2>&1 || true
    fi
done
echo "   ✅ CORS 설정 완료"

# REST API 배포
echo ""
echo "🚀 REST API 배포 중..."
aws apigateway create-deployment \
    --rest-api-id ${REST_API_ID} \
    --stage-name ${API_STAGE} \
    --region ${AWS_REGION} >/dev/null

REST_API_URL="https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}"
echo "   ✅ REST API 배포 완료: ${REST_API_URL}"

# WebSocket API 생성
WEBSOCKET_API_NAME="${SERVICE_NAME}-websocket-api-${STACK_SUFFIX}"
echo ""
echo "🔌 WebSocket API 생성/확인 중..."

# 기존 WebSocket API 확인
EXISTING_WS_API=$(aws apigatewayv2 get-apis --region ${AWS_REGION} \
    --query "Items[?Name=='${WEBSOCKET_API_NAME}'].ApiId" --output text 2>/dev/null || echo "")

if [ ! -z "${EXISTING_WS_API}" ]; then
    WEBSOCKET_API_ID=${EXISTING_WS_API}
    echo "   ✅ WebSocket API 존재함: ${WEBSOCKET_API_ID}"
else
    echo "   🔄 WebSocket API 생성 중..."
    WEBSOCKET_API_ID=$(aws apigatewayv2 create-api \
        --name ${WEBSOCKET_API_NAME} \
        --protocol-type WEBSOCKET \
        --route-selection-expression '$request.body.action' \
        --region ${AWS_REGION} \
        --query 'ApiId' \
        --output text)
    echo "   ✅ WebSocket API 생성 완료: ${WEBSOCKET_API_ID}"
fi

# WebSocket 라우트 생성
echo ""
echo "🔧 WebSocket 라우트 설정 중..."

# $connect 라우트
aws apigatewayv2 create-route \
    --api-id ${WEBSOCKET_API_ID} \
    --route-key '$connect' \
    --target "integrations/${WEBSOCKET_API_ID}" \
    --region ${AWS_REGION} >/dev/null 2>&1 || true

# $disconnect 라우트
aws apigatewayv2 create-route \
    --api-id ${WEBSOCKET_API_ID} \
    --route-key '$disconnect' \
    --target "integrations/${WEBSOCKET_API_ID}" \
    --region ${AWS_REGION} >/dev/null 2>&1 || true

# $default 라우트
aws apigatewayv2 create-route \
    --api-id ${WEBSOCKET_API_ID} \
    --route-key '$default' \
    --target "integrations/${WEBSOCKET_API_ID}" \
    --region ${AWS_REGION} >/dev/null 2>&1 || true

echo "   ✅ WebSocket 라우트 설정 완료"

# WebSocket API 배포
echo ""
echo "🚀 WebSocket API 배포 중..."
aws apigatewayv2 create-deployment \
    --api-id ${WEBSOCKET_API_ID} \
    --stage-name ${API_STAGE} \
    --region ${AWS_REGION} >/dev/null 2>&1 || true

aws apigatewayv2 create-stage \
    --api-id ${WEBSOCKET_API_ID} \
    --stage-name ${API_STAGE} \
    --deployment-id $(aws apigatewayv2 get-deployments --api-id ${WEBSOCKET_API_ID} --region ${AWS_REGION} --query 'Items[0].DeploymentId' --output text) \
    --region ${AWS_REGION} >/dev/null 2>&1 || true

WEBSOCKET_API_URL="wss://${WEBSOCKET_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}"
echo "   ✅ WebSocket API 배포 완료: ${WEBSOCKET_API_URL}"

# .env.deploy 파일 업데이트
echo ""
echo "📝 .env.deploy 파일 업데이트 중..."
sed -i.bak "s|REST_API_ID=.*|REST_API_ID=${REST_API_ID}|" .env.deploy
sed -i.bak "s|WEBSOCKET_API_ID=.*|WEBSOCKET_API_ID=${WEBSOCKET_API_ID}|" .env.deploy
rm -f .env.deploy.bak

# frontend/.env 파일 업데이트
if [ -f "frontend/.env" ]; then
    echo "📝 frontend/.env 파일 업데이트 중..."
    cat > frontend/.env.tmp <<EOF
# NEXUS SERVICE CONFIGURATION
# Template Version: 2.0.0
# Auto-updated by create-api-gateway.sh

# API 설정
VITE_REST_API_URL=${REST_API_URL}
VITE_WEBSOCKET_URL=${WEBSOCKET_API_URL}
VITE_API_BASE_URL=${REST_API_URL}
VITE_WS_URL=${WEBSOCKET_API_URL}

# AWS API Gateway - 서비스 엔드포인트
VITE_API_URL=${REST_API_URL}
VITE_PROMPT_API_URL=${REST_API_URL}
VITE_WEBSOCKET_URL=${WEBSOCKET_API_URL}
VITE_USAGE_API_URL=${REST_API_URL}
VITE_CONVERSATION_API_URL=${REST_API_URL}

# 기존 설정 유지
VITE_AWS_REGION=${AWS_REGION}
VITE_COGNITO_USER_POOL_ID=\${COGNITO_USER_POOL_ID}
VITE_COGNITO_CLIENT_ID=\${COGNITO_CLIENT_ID}
VITE_PDFJS_CDN_URL=https://cdnjs.cloudflare.com/ajax/libs/pdf.js
VITE_USE_MOCK=false
VITE_SERVICE_TYPE=${STACK_SUFFIX}
VITE_ADMIN_EMAIL=${ADMIN_EMAIL}
EOF
    mv frontend/.env.tmp frontend/.env
fi

echo ""
echo "========================================="
echo "   ✅ API Gateway 생성 완료"
echo "========================================="
echo ""
echo "📡 REST API:"
echo "   ID: ${REST_API_ID}"
echo "   URL: ${REST_API_URL}"
echo ""
echo "🔌 WebSocket API:"
echo "   ID: ${WEBSOCKET_API_ID}"
echo "   URL: ${WEBSOCKET_API_URL}"
echo ""
echo "💡 환경변수 파일이 자동 업데이트되었습니다:"
echo "   - .env.deploy"
echo "   - frontend/.env"
echo ""
echo "다음 단계:"
echo "   1. Cognito 설정: ./2-infrastructure/create-cognito.sh"
echo "   2. 프론트엔드 배포: ./3-deploy/deploy-frontend.sh"
echo ""