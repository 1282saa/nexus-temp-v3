#!/bin/bash

# NEXUS TEMPLATE - CloudFront 생성 스크립트
# CloudFront 배포를 생성하여 S3 정적 웹사이트를 CDN으로 제공

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 프로젝트 루트로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 환경변수 파일 로드
if [ ! -f ".env.deploy" ]; then
    echo -e "${RED}❌ .env.deploy 파일이 없습니다.${NC}"
    echo "먼저 ./1-setup/configure.sh를 실행하여 설정을 완료하세요."
    exit 1
fi

source .env.deploy

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   CloudFront 배포 생성${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "서비스: ${SERVICE_NAME}"
echo "S3 버킷: ${SERVICE_NAME}-${STACK_SUFFIX}-frontend"
echo "리전: ${AWS_REGION}"
echo ""

# S3 버킷 이름
S3_BUCKET="${SERVICE_NAME}-${STACK_SUFFIX}-frontend"
CLOUDFRONT_DISTRIBUTION_ID=""

# AWS 계정 ID 가져오기
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS 계정 ID: ${ACCOUNT_ID}"
echo ""

# 1. S3 버킷 웹사이트 설정이 되어있는지 확인
echo -e "${YELLOW}📦 S3 버킷 웹사이트 설정 확인 중...${NC}"
aws s3 website "s3://${S3_BUCKET}" \
    --index-document index.html \
    --error-document error.html 2>/dev/null || true

# 2. S3 버킷을 퍼블릭으로 설정 (CloudFront 없이도 접근 가능하도록)
echo -e "${YELLOW}🔓 S3 버킷 퍼블릭 액세스 설정 중...${NC}"

# 퍼블릭 액세스 차단 해제
aws s3api put-public-access-block \
    --bucket "${S3_BUCKET}" \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" 2>/dev/null || true

# S3 버킷 정책 (퍼블릭 읽기 허용)
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

aws s3api put-bucket-policy --bucket "$S3_BUCKET" --policy file:///tmp/bucket-policy.json 2>/dev/null || true
rm /tmp/bucket-policy.json
echo -e "${GREEN}✅ S3 버킷 퍼블릭 액세스 설정 완료${NC}"

# 3. CloudFront 배포 생성
echo -e "${YELLOW}🌐 CloudFront 배포 확인 중...${NC}"

# 기존 CloudFront 배포 확인
EXISTING_DISTRIBUTION=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Comment=='${SERVICE_NAME}-${STACK_SUFFIX}'].Id" \
    --output text 2>/dev/null || true)

if [ -n "$EXISTING_DISTRIBUTION" ]; then
    echo -e "${GREEN}✅ 기존 CloudFront 배포 발견: $EXISTING_DISTRIBUTION${NC}"
    CLOUDFRONT_DISTRIBUTION_ID="$EXISTING_DISTRIBUTION"
    
    # 도메인 이름 가져오기
    CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --query "Distribution.DomainName" \
        --output text)
else
    echo -e "${YELLOW}🚀 새 CloudFront 배포 생성 중...${NC}"
    
    # S3 웹사이트 엔드포인트 형식
    if [ "$AWS_REGION" = "us-east-1" ]; then
        S3_WEBSITE_ENDPOINT="${S3_BUCKET}.s3-website-us-east-1.amazonaws.com"
    else
        S3_WEBSITE_ENDPOINT="${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
    fi
    
    # CloudFront 설정 파일 생성 (S3 웹사이트를 Origin으로 사용)
    cat > /tmp/cloudfront-config.json <<EOF
{
    "CallerReference": "${SERVICE_NAME}-${STACK_SUFFIX}-$(date +%s)",
    "Comment": "${SERVICE_NAME}-${STACK_SUFFIX}",
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "${S3_BUCKET}",
                "DomainName": "${S3_WEBSITE_ENDPOINT}",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only",
                    "OriginSslProtocols": {
                        "Quantity": 3,
                        "Items": ["TLSv1", "TLSv1.1", "TLSv1.2"]
                    },
                    "OriginReadTimeout": 30,
                    "OriginKeepaliveTimeout": 5
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "${S3_BUCKET}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            },
            "Headers": {
                "Quantity": 0
            },
            "QueryStringCacheKeys": {
                "Quantity": 0
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true
    },
    "CustomErrorResponses": {
        "Quantity": 2,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponseCode": "200",
                "ResponsePagePath": "/index.html",
                "ErrorCachingMinTTL": 0
            },
            {
                "ErrorCode": 403,
                "ResponseCode": "200",
                "ResponsePagePath": "/index.html",
                "ErrorCachingMinTTL": 0
            }
        ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100",
    "ViewerCertificate": {
        "CloudFrontDefaultCertificate": true
    },
    "HttpVersion": "http2"
}
EOF
    
    # CloudFront 배포 생성
    DISTRIBUTION_RESULT=$(aws cloudfront create-distribution \
        --distribution-config file:///tmp/cloudfront-config.json \
        --output json)
    
    CLOUDFRONT_DISTRIBUTION_ID=$(echo "$DISTRIBUTION_RESULT" | grep -o '"Id": "[^"]*"' | head -1 | cut -d'"' -f4)
    CLOUDFRONT_DOMAIN=$(echo "$DISTRIBUTION_RESULT" | grep -o '"DomainName": "[^"]*"' | head -1 | cut -d'"' -f4)
    
    rm /tmp/cloudfront-config.json
    
    echo -e "${GREEN}✅ CloudFront 배포 생성 완료${NC}"
    echo "   Distribution ID: $CLOUDFRONT_DISTRIBUTION_ID"
    echo "   Domain: $CLOUDFRONT_DOMAIN"
fi

# 4. .env.deploy 파일 업데이트
echo -e "${YELLOW}📝 환경 변수 파일 업데이트 중...${NC}"

# CLOUDFRONT_ID가 없으면 추가
if ! grep -q "^CLOUDFRONT_ID=" .env.deploy; then
    echo "" >> .env.deploy
    echo "# CloudFront 설정" >> .env.deploy
    echo "CLOUDFRONT_ID=$CLOUDFRONT_DISTRIBUTION_ID" >> .env.deploy
    echo "CLOUDFRONT_DOMAIN=$CLOUDFRONT_DOMAIN" >> .env.deploy
else
    # 기존 값 업데이트
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^CLOUDFRONT_ID=.*|CLOUDFRONT_ID=$CLOUDFRONT_DISTRIBUTION_ID|" .env.deploy
        sed -i '' "s|^CLOUDFRONT_DOMAIN=.*|CLOUDFRONT_DOMAIN=$CLOUDFRONT_DOMAIN|" .env.deploy
    else
        sed -i "s|^CLOUDFRONT_ID=.*|CLOUDFRONT_ID=$CLOUDFRONT_DISTRIBUTION_ID|" .env.deploy
        sed -i "s|^CLOUDFRONT_DOMAIN=.*|CLOUDFRONT_DOMAIN=$CLOUDFRONT_DOMAIN|" .env.deploy
    fi
fi

echo -e "${GREEN}✅ 환경 변수 파일 업데이트 완료${NC}"

# 5. 결과 출력
echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}✅ CloudFront 설정 완료!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}📌 접속 가능한 URL:${NC}"
echo "   S3 웹사이트: http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
echo "   CloudFront: https://$CLOUDFRONT_DOMAIN"
echo ""
echo -e "${YELLOW}⏳ 참고사항:${NC}"
echo "   - CloudFront 배포가 전 세계에 전파되는데 15-20분 정도 소요됩니다"
echo "   - 상태가 'Deployed'가 되면 접속 가능합니다"
echo "   - 캐시 무효화: aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths '/*'"
echo ""
echo -e "${GREEN}🌐 권장 접속 URL: https://$CLOUDFRONT_DOMAIN${NC}"
echo ""