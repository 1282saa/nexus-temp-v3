#!/bin/bash

# NEXUS TEMPLATE - 백엔드 배포 스크립트
# 템플릿 버전: 2.0.0
set -e

# 환경변수 파일 로드
if [ ! -f ".env.deploy" ]; then
    echo "❌ .env.deploy 파일이 없습니다."
    echo "먼저 ./configure.sh를 실행하여 설정을 완료하세요."
    exit 1
fi

# 설정 로드
source .env.deploy

echo "========================================="
echo "   ${SERVICE_NAME} Lambda 함수 배포"
echo "========================================="
echo ""
echo "서비스: ${SERVICE_NAME}"
echo "환경: ${ENVIRONMENT}"
echo ""

# 프로젝트 루트로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Lambda 함수 목록
LAMBDA_FUNCTIONS=(
    "${SERVICE_NAME}-conversation-api-${STACK_SUFFIX}"
    "${SERVICE_NAME}-prompt-crud-${STACK_SUFFIX}"
    "${SERVICE_NAME}-usage-handler-${STACK_SUFFIX}"
    "${SERVICE_NAME}-websocket-connect-${STACK_SUFFIX}"
    "${SERVICE_NAME}-websocket-disconnect-${STACK_SUFFIX}"
    "${SERVICE_NAME}-websocket-message-${STACK_SUFFIX}"
)

# 1. 배포 패키지 생성
echo "📦 Lambda 배포 패키지 생성 중..."
cd "${PROJECT_ROOT}/backend"

# 기존 패키지 삭제
rm -f lambda-deployment.zip

# ZIP 파일 생성
cd extracted
zip -r ../lambda-deployment.zip . -x "*.pyc" -x "__pycache__/*" -x ".env*"
cd ..

if [ ! -f lambda-deployment.zip ]; then
    echo "❌ 배포 패키지 생성 실패"
    exit 1
fi

PACKAGE_SIZE=$(ls -lh lambda-deployment.zip | awk '{print $5}')
echo "✅ 배포 패키지 생성 완료 (크기: ${PACKAGE_SIZE})"

# 2. Lambda 함수 업데이트
echo ""
echo "⚡ Lambda 함수 업데이트 중..."

for FUNCTION_NAME in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "   🔄 ${FUNCTION_NAME} 업데이트 중..."
    
    # 함수 존재 여부 확인
    if aws lambda get-function --function-name ${FUNCTION_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
        # 함수 업데이트
        aws lambda update-function-code \
            --function-name ${FUNCTION_NAME} \
            --zip-file fileb://lambda-deployment.zip \
            --region ${AWS_REGION} \
            --output text > /dev/null
        
        if [ $? -eq 0 ]; then
            echo "      ✅ 완료"
        else
            echo "      ❌ 실패"
        fi
    else
        echo "      ⚠️  함수가 존재하지 않음 (건너뜀)"
    fi
done

# 3. 환경변수 업데이트 (필요시)
if [ "${UPDATE_ENV_VARS}" = "true" ]; then
    echo ""
    echo "🔧 Lambda 환경변수 업데이트 중..."
    
    for FUNCTION_NAME in "${LAMBDA_FUNCTIONS[@]}"; do
        echo "   📝 ${FUNCTION_NAME} 환경변수 업데이트..."
        
        # 환경변수 JSON 생성
        ENV_JSON=$(cat <<EOF
{
    "Variables": {
        "AWS_REGION": "${AWS_REGION}",
        "SERVICE_NAME": "${SERVICE_NAME}",
        "STACK_SUFFIX": "${STACK_SUFFIX}",
        "ENVIRONMENT": "${ENVIRONMENT}",
        "REST_API_URL": "https://${REST_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}",
        "WEBSOCKET_API_URL": "wss://${WEBSOCKET_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${API_STAGE}",
        "ENABLE_NEWS_SEARCH": "${ENABLE_NEWS_SEARCH}"
    }
}
EOF
        )
        
        # 환경변수 업데이트
        if aws lambda get-function --function-name ${FUNCTION_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
            aws lambda update-function-configuration \
                --function-name ${FUNCTION_NAME} \
                --environment "${ENV_JSON}" \
                --region ${AWS_REGION} \
                --output text > /dev/null
            
            if [ $? -eq 0 ]; then
                echo "      ✅ 완료"
            else
                echo "      ⚠️  실패 (계속 진행)"
            fi
        fi
    done
fi

# 결과 출력
echo ""
echo "========================================="
echo "✅ Lambda 배포 완료!"
echo "========================================="
echo ""
echo "📋 배포 정보:"
echo "   배포 시각: $(date '+%Y-%m-%d %H:%M:%S')"
echo "   패키지 크기: ${PACKAGE_SIZE}"
echo "   Lambda 함수: ${#LAMBDA_FUNCTIONS[@]}개"
echo ""
echo "🔍 로그 확인:"
echo "   aws logs tail /aws/lambda/${SERVICE_NAME}-${STACK_SUFFIX} --follow"
echo ""

cd "${PROJECT_ROOT}"