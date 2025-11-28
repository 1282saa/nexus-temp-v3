#!/bin/bash

# NEXUS TEMPLATE - Lambda 함수 생성 스크립트
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
echo "   ⚡ Lambda 함수 생성"
echo "========================================="
echo ""
echo "서비스: ${SERVICE_NAME}"
echo "환경: ${STACK_SUFFIX}"
echo ""

# IAM 역할 생성 (Lambda 실행 역할)
ROLE_NAME="${SERVICE_NAME}-lambda-role-${STACK_SUFFIX}"
ROLE_ARN=""

echo "🔐 IAM 역할 확인 중..."
if aws iam get-role --role-name ${ROLE_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
    echo "   ✅ IAM 역할 존재함: ${ROLE_NAME}"
    ROLE_ARN=$(aws iam get-role --role-name ${ROLE_NAME} --query 'Role.Arn' --output text)
else
    echo "   ⚠️  IAM 역할 생성 중..."
    
    # Trust policy
    cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # 역할 생성
    ROLE_ARN=$(aws iam create-role \
        --role-name ${ROLE_NAME} \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --query 'Role.Arn' \
        --output text)
    
    # 정책 연결
    aws iam attach-role-policy \
        --role-name ${ROLE_NAME} \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    
    aws iam attach-role-policy \
        --role-name ${ROLE_NAME} \
        --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
    
    aws iam attach-role-policy \
        --role-name ${ROLE_NAME} \
        --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess
    
    # Bedrock 접근 정책
    cat > /tmp/bedrock-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:InvokeModelWithResponseStream"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    aws iam put-role-policy \
        --role-name ${ROLE_NAME} \
        --policy-name BedrockAccess \
        --policy-document file:///tmp/bedrock-policy.json
    
    echo "   ✅ IAM 역할 생성 완료"
    
    # IAM 역할이 활성화될 때까지 대기
    echo "   ⏳ IAM 역할 활성화 대기 중 (10초)..."
    sleep 10
fi

# Lambda 함수 목록
LAMBDA_FUNCTIONS=(
    "${SERVICE_NAME}-conversation-api-${STACK_SUFFIX}"
    "${SERVICE_NAME}-prompt-crud-${STACK_SUFFIX}"
    "${SERVICE_NAME}-usage-handler-${STACK_SUFFIX}"
    "${SERVICE_NAME}-websocket-connect-${STACK_SUFFIX}"
    "${SERVICE_NAME}-websocket-disconnect-${STACK_SUFFIX}"
    "${SERVICE_NAME}-websocket-message-${STACK_SUFFIX}"
)

# 핸들러 매핑 함수
get_handler_for_function() {
    local FUNC_NAME=$1
    case $FUNC_NAME in
        *conversation-api*) echo "handlers.api.conversation.handler" ;;
        *prompt-crud*) echo "handlers.api.prompt.handler" ;;
        *usage-handler*) echo "handlers.api.usage.handler" ;;
        *websocket-connect*) echo "handlers.websocket.connect.handler" ;;
        *websocket-disconnect*) echo "handlers.websocket.disconnect.handler" ;;
        *websocket-message*) echo "handlers.websocket.message.handler" ;;
        *) echo "index.handler" ;;
    esac
}

# 초기 Lambda 코드 생성 (최소한의 코드)
echo ""
echo "📦 초기 Lambda 패키지 생성 중..."
TEMP_DIR="/tmp/lambda-init-${SERVICE_NAME}"
mkdir -p ${TEMP_DIR}/handlers/api
mkdir -p ${TEMP_DIR}/handlers/websocket

# 기본 핸들러 파일 생성
cat > ${TEMP_DIR}/handlers/__init__.py <<EOF
# Lambda handlers package
EOF

# API 핸들러
cat > ${TEMP_DIR}/handlers/api/__init__.py <<EOF
# API handlers
EOF

cat > ${TEMP_DIR}/handlers/api/conversation.py <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Conversation API - ${SERVICE_NAME}',
            'function': context.function_name
        })
    }
EOF

cat > ${TEMP_DIR}/handlers/api/prompt.py <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Prompt API - ${SERVICE_NAME}',
            'function': context.function_name
        })
    }
EOF

cat > ${TEMP_DIR}/handlers/api/usage.py <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Usage API - ${SERVICE_NAME}',
            'function': context.function_name
        })
    }
EOF

# WebSocket 핸들러
cat > ${TEMP_DIR}/handlers/websocket/__init__.py <<EOF
# WebSocket handlers
EOF

cat > ${TEMP_DIR}/handlers/websocket/connect.py <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Connected')
    }
EOF

cat > ${TEMP_DIR}/handlers/websocket/disconnect.py <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Disconnected')
    }
EOF

cat > ${TEMP_DIR}/handlers/websocket/message.py <<EOF
import json
import boto3
import os

def handler(event, context):
    # WebSocket 메시지 처리
    body = json.loads(event.get('body', '{}'))
    
    # Echo back for now
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Message received',
            'echo': body
        })
    }
EOF

# ZIP 파일 생성
cd ${TEMP_DIR}
zip -r lambda-init.zip . -q
cd - > /dev/null

echo "✅ 초기 패키지 생성 완료"

# Lambda 함수 생성
echo ""
echo "⚡ Lambda 함수 생성 중..."

for FUNCTION_NAME in "${LAMBDA_FUNCTIONS[@]}"; do
    HANDLER=$(get_handler_for_function "$FUNCTION_NAME")
    
    if aws lambda get-function --function-name ${FUNCTION_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
        echo "   ✅ ${FUNCTION_NAME} (이미 존재함)"
    else
        echo "   🔄 ${FUNCTION_NAME} 생성 중..."
        
        # 환경변수 설정
        ENV_VARS='{"SERVICE_NAME":"'${SERVICE_NAME}'","STACK_SUFFIX":"'${STACK_SUFFIX}'","ENVIRONMENT":"'${ENVIRONMENT}'","AWS_REGION":"'${AWS_REGION}'","CONVERSATIONS_TABLE":"'${SERVICE_NAME}'-conversations-'${STACK_SUFFIX}'","PROMPTS_TABLE":"'${SERVICE_NAME}'-prompts-'${STACK_SUFFIX}'","USAGE_TABLE":"'${SERVICE_NAME}'-usage-'${STACK_SUFFIX}'","WEBSOCKET_TABLE":"'${SERVICE_NAME}'-websocket-connections-'${STACK_SUFFIX}'","FILES_TABLE":"'${SERVICE_NAME}'-files-'${STACK_SUFFIX}'","MESSAGES_TABLE":"'${SERVICE_NAME}'-messages-'${STACK_SUFFIX}'","LOG_LEVEL":"INFO"}'
        
        # Lambda 함수 생성 (환경변수 없이 먼저 생성)
        aws lambda create-function \
            --function-name ${FUNCTION_NAME} \
            --runtime python3.11 \
            --role ${ROLE_ARN} \
            --handler ${HANDLER} \
            --zip-file fileb://${TEMP_DIR}/lambda-init.zip \
            --timeout 120 \
            --memory-size 1024 \
            --region ${AWS_REGION} \
            --output text > /dev/null
        
        # 환경변수는 별도로 업데이트
        if [ $? -eq 0 ]; then
            aws lambda update-function-configuration \
                --function-name ${FUNCTION_NAME} \
                --environment "Variables={SERVICE_NAME=${SERVICE_NAME},STACK_SUFFIX=${STACK_SUFFIX},ENVIRONMENT=${ENVIRONMENT},AWS_REGION=${AWS_REGION},CONVERSATIONS_TABLE=${SERVICE_NAME}-conversations-${STACK_SUFFIX},PROMPTS_TABLE=${SERVICE_NAME}-prompts-${STACK_SUFFIX},USAGE_TABLE=${SERVICE_NAME}-usage-${STACK_SUFFIX},WEBSOCKET_TABLE=${SERVICE_NAME}-websocket-connections-${STACK_SUFFIX},FILES_TABLE=${SERVICE_NAME}-files-${STACK_SUFFIX},MESSAGES_TABLE=${SERVICE_NAME}-messages-${STACK_SUFFIX},LOG_LEVEL=INFO}" \
                --region ${AWS_REGION} \
                --output text > /dev/null 2>&1 || true
        fi
        
        if [ $? -eq 0 ]; then
            echo "      ✅ 생성 완료"
        else
            echo "      ❌ 생성 실패"
        fi
    fi
done

# 정리
rm -rf ${TEMP_DIR}
rm -f /tmp/trust-policy.json
rm -f /tmp/bedrock-policy.json

echo ""
echo "========================================="
echo "   ✅ Lambda 함수 생성 완료"
echo "========================================="
echo ""
echo "생성된 Lambda 함수: ${#LAMBDA_FUNCTIONS[@]}개"
echo "IAM 역할: ${ROLE_NAME}"
echo ""
echo "💡 다음 단계:"
echo "   1. API Gateway 생성: ./2-infrastructure/create-api-gateway.sh"
echo "   2. 실제 코드 배포: ./3-deploy/deploy-backend.sh"
echo ""