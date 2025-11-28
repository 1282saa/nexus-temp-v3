#!/bin/bash

# NEXUS TEMPLATE - 통합 배포 스크립트
# 버전: 2.0.0
# 특징: 멱등성 보장 (여러 번 실행해도 안전)

set -e

echo "========================================="
echo "   🚀 NEXUS TEMPLATE 스마트 배포"
echo "========================================="
echo ""

# 환경변수 확인
if [ ! -f ".env.deploy" ]; then
    echo "❌ .env.deploy 파일이 없습니다."
    echo "먼저 ./configure.sh를 실행하여 설정을 완료하세요."
    exit 1
fi

source .env.deploy

# 배포 모드 선택
echo "배포 옵션을 선택하세요:"
echo "  1) 코드만 배포 (프론트엔드/백엔드 업데이트)"
echo "  2) 인프라 확인 및 생성 (처음 설정시)"
echo "  3) 전체 배포 (인프라 + 코드)"
echo ""
read -p "선택 (1-3): " DEPLOY_MODE

case $DEPLOY_MODE in
    1)
        echo ""
        echo "📦 코드 배포 모드"
        echo "=================="
        
        # 변경사항 확인
        echo "🔍 변경사항 확인 중..."
        
        # Frontend 변경 확인
        FRONTEND_CHANGED=false
        if [ -d "frontend/dist" ]; then
            # 마지막 배포 시간 확인
            if [ -f ".last-deploy-frontend" ]; then
                LAST_DEPLOY=$(cat .last-deploy-frontend)
                # src 폴더의 최신 수정 시간 확인
                LATEST_CHANGE=$(find frontend/src -type f -newer .last-deploy-frontend 2>/dev/null | head -1)
                if [ ! -z "$LATEST_CHANGE" ]; then
                    FRONTEND_CHANGED=true
                    echo "   ✅ Frontend 변경 감지"
                fi
            else
                FRONTEND_CHANGED=true
                echo "   ✅ Frontend 초기 배포 필요"
            fi
        else
            FRONTEND_CHANGED=true
            echo "   ✅ Frontend 빌드 필요"
        fi
        
        # Backend 변경 확인
        BACKEND_CHANGED=false
        if [ -f ".last-deploy-backend" ]; then
            LATEST_CHANGE=$(find backend/extracted -type f -newer .last-deploy-backend 2>/dev/null | head -1)
            if [ ! -z "$LATEST_CHANGE" ]; then
                BACKEND_CHANGED=true
                echo "   ✅ Backend 변경 감지"
            fi
        else
            BACKEND_CHANGED=true
            echo "   ✅ Backend 초기 배포 필요"
        fi
        
        # 배포 실행
        if [ "$FRONTEND_CHANGED" = true ]; then
            echo ""
            echo "🚀 Frontend 배포 중..."
            ./deploy-frontend.sh
            date > .last-deploy-frontend
        else
            echo "   ⏭️  Frontend 변경 없음 (건너뜀)"
        fi
        
        if [ "$BACKEND_CHANGED" = true ]; then
            echo ""
            echo "🚀 Backend 배포 중..."
            ./deploy-backend.sh
            date > .last-deploy-backend
        else
            echo "   ⏭️  Backend 변경 없음 (건너뜀)"
        fi
        
        if [ "$FRONTEND_CHANGED" = false ] && [ "$BACKEND_CHANGED" = false ]; then
            echo ""
            echo "ℹ️  변경사항이 없습니다. 배포할 내용이 없습니다."
        fi
        ;;
        
    2)
        echo ""
        echo "🏗️ 인프라 확인 모드"
        echo "==================="
        
        # DynamoDB 테이블 확인/생성
        echo "📊 DynamoDB 테이블 확인 중..."
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
                echo "   ✅ $TABLE (존재함)"
            else
                echo "   ⚠️  $TABLE (생성 필요)"
                echo "      생성 중..."
                aws dynamodb create-table \
                    --table-name $TABLE \
                    --attribute-definitions AttributeName=id,AttributeType=S \
                    --key-schema AttributeName=id,KeyType=HASH \
                    --billing-mode PAY_PER_REQUEST \
                    --region $AWS_REGION >/dev/null
                echo "      ✅ 생성 완료"
            fi
        done
        
        # S3 버킷 확인/생성
        echo ""
        echo "🪣 S3 버킷 확인 중..."
        if aws s3api head-bucket --bucket $S3_BUCKET --region $AWS_REGION 2>/dev/null; then
            echo "   ✅ $S3_BUCKET (존재함)"
        else
            echo "   ⚠️  $S3_BUCKET (생성 필요)"
            echo "      생성 중..."
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
            echo "      ✅ 생성 완료"
        fi
        
        # Lambda 함수 확인
        echo ""
        echo "⚡ Lambda 함수 확인 중..."
        LAMBDA_FUNCTIONS=(
            "${SERVICE_NAME}-conversation-api-${STACK_SUFFIX}"
            "${SERVICE_NAME}-prompt-crud-${STACK_SUFFIX}"
            "${SERVICE_NAME}-usage-handler-${STACK_SUFFIX}"
            "${SERVICE_NAME}-websocket-connect-${STACK_SUFFIX}"
            "${SERVICE_NAME}-websocket-disconnect-${STACK_SUFFIX}"
            "${SERVICE_NAME}-websocket-message-${STACK_SUFFIX}"
        )
        
        for FUNC in "${LAMBDA_FUNCTIONS[@]}"; do
            if aws lambda get-function --function-name $FUNC --region $AWS_REGION >/dev/null 2>&1; then
                echo "   ✅ $FUNC (존재함)"
            else
                echo "   ⚠️  $FUNC (생성 필요)"
                # 실제 Lambda 생성은 더 복잡하므로 별도 스크립트 필요
                echo "      → scripts-v2/create-lambda.sh 실행 필요"
            fi
        done
        
        # API Gateway 확인
        if [ ! -z "$REST_API_ID" ]; then
            echo ""
            echo "🌐 API Gateway 확인 중..."
            if aws apigateway get-rest-api --rest-api-id $REST_API_ID --region $AWS_REGION >/dev/null 2>&1; then
                echo "   ✅ REST API: $REST_API_ID (존재함)"
            else
                echo "   ⚠️  REST API가 존재하지 않습니다"
            fi
        fi
        
        echo ""
        echo "✅ 인프라 확인 완료"
        ;;
        
    3)
        echo ""
        echo "🔄 전체 배포 모드"
        echo "=================="
        
        # 인프라 확인
        $0 2
        
        # 코드 배포
        echo ""
        read -p "코드 배포를 계속하시겠습니까? (y/n): " CONTINUE
        if [ "$CONTINUE" = "y" ] || [ "$CONTINUE" = "Y" ]; then
            $0 1
        fi
        ;;
        
    *)
        echo "❌ 잘못된 선택입니다."
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "   ✅ 배포 프로세스 완료"
echo "========================================="
echo ""
echo "📊 배포 상태:"
echo "   서비스: ${SERVICE_NAME}"
echo "   환경: ${ENVIRONMENT}"
echo "   리전: ${AWS_REGION}"
if [ ! -z "$CUSTOM_DOMAIN" ]; then
    echo "   URL: https://${CUSTOM_DOMAIN}"
fi
echo ""
echo "💡 팁:"
echo "   - 로그 확인: aws logs tail /aws/lambda/${SERVICE_NAME}-${STACK_SUFFIX} --follow"
echo "   - 강제 배포: rm .last-deploy-* && ./deploy.sh"
echo ""