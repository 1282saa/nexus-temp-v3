#!/bin/bash

# NEXUS TEMPLATE - 빠른 시작 스크립트
# 기본값으로 모든 설정을 자동으로 진행합니다
# 비개발자를 위한 원클릭 설치

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║     🚀 NEXUS TEMPLATE - 빠른 시작 모드 🚀                ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║     AI 채팅 서비스를 자동으로 구축합니다                 ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╗${NC}"
echo ""

# 필수 도구 확인
echo -e "${YELLOW}📋 시스템 요구사항 확인 중...${NC}"
echo ""

MISSING_TOOLS=0

# AWS CLI 체크
if command -v aws &> /dev/null; then
    echo -e "  ✅ AWS CLI 설치됨"
else
    echo -e "  ❌ AWS CLI가 설치되지 않았습니다"
    echo -e "     👉 설치 방법: https://aws.amazon.com/cli/"
    MISSING_TOOLS=1
fi

# Node.js 체크
if command -v node &> /dev/null; then
    echo -e "  ✅ Node.js 설치됨"
else
    echo -e "  ❌ Node.js가 설치되지 않았습니다"
    echo -e "     👉 설치 방법: https://nodejs.org/"
    MISSING_TOOLS=1
fi

# AWS 인증 체크
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    echo -e "  ✅ AWS 계정: $AWS_ACCOUNT"
else
    echo -e "  ❌ AWS 로그인이 필요합니다"
    echo -e "     👉 실행: aws configure"
    MISSING_TOOLS=1
fi

if [ $MISSING_TOOLS -eq 1 ]; then
    echo ""
    echo -e "${RED}❌ 필수 도구를 먼저 설치/설정해주세요.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ 모든 요구사항이 충족되었습니다!${NC}"
echo ""

# 서비스 이름 생성 (타임스탬프 기반)
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DEFAULT_SERVICE_NAME="my-nexus-${TIMESTAMP:8:6}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}서비스 설정${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "서비스 이름을 입력하세요."
echo "아무것도 입력하지 않으면 자동으로 생성됩니다."
echo ""
read -p "서비스 이름 (기본: $DEFAULT_SERVICE_NAME): " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-$DEFAULT_SERVICE_NAME}

# 서비스 이름 유효성 검사 (영문자, 숫자, 하이픈만 허용)
if [[ ! "$SERVICE_NAME" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]]; then
    echo -e "${YELLOW}⚠️  서비스 이름을 자동 수정합니다 (특수문자 제거)${NC}"
    SERVICE_NAME=$(echo "$SERVICE_NAME" | sed 's/[^a-zA-Z0-9-]//g' | sed 's/^-*//')
    if [ -z "$SERVICE_NAME" ]; then
        SERVICE_NAME=$DEFAULT_SERVICE_NAME
    fi
    echo "   수정된 이름: $SERVICE_NAME"
fi

echo ""
echo -e "${GREEN}설정된 서비스 이름: $SERVICE_NAME${NC}"
echo ""

# 환경 설정 파일 생성
echo -e "${YELLOW}📝 설정 파일 생성 중...${NC}"

cat > .env.deploy <<EOF
# NEXUS TEMPLATE 배포 설정
# 생성일: $(date)
# 빠른 시작 모드로 생성됨

# 서비스 설정
SERVICE_NAME=$SERVICE_NAME
STACK_SUFFIX=dev
ENVIRONMENT=development

# AWS 설정
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=$AWS_ACCOUNT
API_STAGE=prod

# S3 버킷
S3_BUCKET=${SERVICE_NAME}-dev-frontend

# 관리자 설정
ADMIN_EMAIL=admin@example.com
COMPANY_DOMAIN=@example.com

# 자동 생성됨
CREATED_BY=quick-start
CREATED_AT=$(date +%Y-%m-%d_%H:%M:%S)
EOF

echo -e "${GREEN}✅ 설정 파일 생성 완료${NC}"
echo ""

# 단계별 실행
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}자동 구축 시작${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "다음 단계들이 자동으로 실행됩니다:"
echo "  1. AWS 인프라 생성 (5-10분)"
echo "  2. 환경 변수 설정"
echo "  3. 애플리케이션 배포"
echo ""
read -p "계속하시겠습니까? (Y/n): " CONTINUE

if [ "$CONTINUE" = "n" ] || [ "$CONTINUE" = "N" ]; then
    echo -e "${YELLOW}취소되었습니다.${NC}"
    exit 0
fi

echo ""

# 1. 인프라 생성
echo -e "${CYAN}[1/3] AWS 인프라 생성 중...${NC}"
echo -e "${YELLOW}⏱️  약 5-10분 소요됩니다. 잠시만 기다려주세요...${NC}"
echo ""

if [ -f "2-infrastructure/create-infrastructure.sh" ]; then
    bash 2-infrastructure/create-infrastructure.sh --auto
else
    echo -e "${RED}❌ 인프라 생성 스크립트를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""

# 2. 환경 변수 생성
echo -e "${CYAN}[2/3] 환경 변수 설정 중...${NC}"
echo ""

if [ -f "4-utilities/generate-env.sh" ]; then
    bash 4-utilities/generate-env.sh
else
    echo -e "${RED}❌ 환경 변수 생성 스크립트를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""

# 3. 배포
echo -e "${CYAN}[3/3] 애플리케이션 배포 중...${NC}"
echo ""

# 프론트엔드 배포
if [ -f "3-deploy/deploy-frontend.sh" ]; then
    echo -e "${YELLOW}프론트엔드 배포 중...${NC}"
    bash 3-deploy/deploy-frontend.sh
else
    echo -e "${RED}❌ 프론트엔드 배포 스크립트를 찾을 수 없습니다.${NC}"
fi

echo ""

# 백엔드 배포
if [ -f "3-deploy/deploy-backend.sh" ]; then
    echo -e "${YELLOW}백엔드 배포 중...${NC}"
    bash 3-deploy/deploy-backend.sh
else
    echo -e "${RED}❌ 백엔드 배포 스크립트를 찾을 수 없습니다.${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 축하합니다! 모든 설정이 완료되었습니다!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 접속 정보 표시
if [ -f ".env.deploy" ]; then
    source .env.deploy
    
    echo -e "${PURPLE}📌 서비스 정보:${NC}"
    echo "   서비스 이름: $SERVICE_NAME"
    echo "   환경: $ENVIRONMENT"
    echo ""
    
    if [ -n "$CLOUDFRONT_DOMAIN" ]; then
        echo -e "${GREEN}🌐 접속 URL:${NC}"
        echo -e "${CYAN}   https://$CLOUDFRONT_DOMAIN${NC}"
        echo ""
        echo -e "${YELLOW}⏳ 참고: CloudFront 배포가 완료되는데 15-20분 정도 걸립니다.${NC}"
    else
        echo -e "${GREEN}🌐 접속 URL (S3):${NC}"
        echo -e "${CYAN}   http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com${NC}"
    fi
    
    echo ""
    echo -e "${PURPLE}📚 다음 단계:${NC}"
    echo "   1. 위 URL로 접속하여 서비스 확인"
    echo "   2. 회원가입 후 로그인"
    echo "   3. AI 채팅 서비스 이용"
    echo ""
    echo -e "${YELLOW}💡 팁:${NC}"
    echo "   - 추가 설정: ./start.sh"
    echo "   - 도움말: ./start.sh → 5번 메뉴"
    echo "   - 문제 해결: README.md 참조"
fi

echo ""
echo -e "${GREEN}감사합니다! 🙏${NC}"
echo ""