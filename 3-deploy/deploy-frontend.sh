#!/bin/bash

# NEXUS TEMPLATE - 프론트엔드 배포 스크립트
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
echo "   ${SERVICE_NAME} 프론트엔드 배포"
echo "========================================="
echo ""
echo "서비스: ${SERVICE_NAME}"
echo "환경: ${ENVIRONMENT}"
echo "S3 버킷: ${S3_BUCKET}"
echo "CloudFront ID: ${CLOUDFRONT_ID}"
echo "도메인: ${CUSTOM_DOMAIN}"
echo ""

# 프로젝트 루트로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 1. 프론트엔드 빌드
echo "🔨 프론트엔드 빌드 중..."
cd "${PROJECT_ROOT}/frontend"

# 의존성 설치 (필요한 경우)
if [ ! -d "node_modules" ]; then
    echo "📦 NPM 패키지 설치 중..."
    npm install
fi

# 빌드
echo "⚙️  빌드 실행 중..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ 프론트엔드 빌드 실패"
    exit 1
fi

echo "✅ 프론트엔드 빌드 완료"

# 2. S3에 업로드
echo ""
echo "📤 S3에 파일 업로드 중..."
aws s3 sync dist/ "s3://${S3_BUCKET}/" --delete --region ${AWS_REGION}

if [ $? -ne 0 ]; then
    echo "❌ S3 업로드 실패"
    exit 1
fi

echo "✅ S3 업로드 완료"

# 3. CloudFront 캐시 무효화 (있는 경우)
if [ ! -z "${CLOUDFRONT_ID}" ]; then
    echo ""
    echo "🔄 CloudFront 캐시 무효화 중..."
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id ${CLOUDFRONT_ID} \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    if [ $? -ne 0 ]; then
        echo "⚠️  CloudFront 캐시 무효화 실패 (계속 진행)"
    else
        echo "✅ CloudFront 캐시 무효화 요청 완료 (ID: ${INVALIDATION_ID})"
    fi
fi

# 결과 출력
echo ""
echo "========================================="
echo "✅ 배포 완료!"
echo "========================================="
echo ""
echo "🌐 접속 URL:"
if [ ! -z "${CLOUDFRONT_DOMAIN}" ]; then
    echo "   CloudFront (권장): https://${CLOUDFRONT_DOMAIN}"
fi
echo "   S3 웹사이트: http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
if [ ! -z "${CUSTOM_DOMAIN}" ]; then
    echo "   커스텀 도메인: https://${CUSTOM_DOMAIN}"
fi
echo ""
echo "📋 배포 정보:"
echo "   배포 시각: $(date '+%Y-%m-%d %H:%M:%S')"
echo "   S3 버킷: s3://${S3_BUCKET}/"
if [ ! -z "${CLOUDFRONT_ID}" ]; then
    echo "   CloudFront 배포 ID: ${CLOUDFRONT_ID}"
    echo ""
    echo "⏳ CloudFront 캐시 무효화가 완료되기까지 약 1-2분 소요됩니다."
fi
echo ""

cd "${PROJECT_ROOT}"