#!/bin/bash

# ========================================
# Nexus Template - 자동 설정 및 배포 스크립트
# ========================================
# 이 스크립트 하나로 전체 프로젝트를 설정하고 배포합니다.
# 
# 사용법: ./setup.sh [환경] [프로젝트명]
# 예시: ./setup.sh dev my-chat-service
# ========================================

set -e  # 에러 발생시 중단

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 프로젝트 정보
ENVIRONMENT=${1:-dev}
PROJECT_NAME=${2:-nexus}
AWS_REGION=${3:-us-east-1}

# 로고 출력
print_logo() {
    echo -e "${CYAN}"
    cat << "EOF"
    _   _                     
   | \ | | _____  ___   _ ___ 
   |  \| |/ _ \ \/ / | | / __|
   | |\  |  __/>  <| |_| \__ \
   |_| \_|\___/_/\_\\__,_|___/
   
   AI Chat Service Template
EOF
    echo -e "${NC}"
}

# 진행 상황 출력
print_step() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} ${GREEN}➜${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# 사전 요구사항 체크
check_prerequisites() {
    print_step "사전 요구사항 확인 중..."
    
    # Node.js 체크
    if ! command -v node &> /dev/null; then
        print_error "Node.js가 설치되지 않았습니다."
        echo "설치: https://nodejs.org/"
        exit 1
    fi
    
    # Python 체크
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3가 설치되지 않았습니다."
        echo "설치: https://www.python.org/"
        exit 1
    fi
    
    # AWS CLI 체크
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI가 설치되지 않았습니다."
        echo "설치: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # AWS 자격증명 체크
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS 자격증명이 설정되지 않았습니다."
        echo "실행: aws configure"
        exit 1
    fi
    
    print_success "모든 사전 요구사항 충족"
}

# 프로젝트 정보 수집
collect_project_info() {
    print_step "프로젝트 설정 정보 수집..."
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}프로젝트 설정${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # 프로젝트명
    read -p "프로젝트 이름 [$PROJECT_NAME]: " input
    PROJECT_NAME=${input:-$PROJECT_NAME}
    
    # 환경
    echo "배포 환경 선택:"
    echo "  1) dev (개발)"
    echo "  2) staging (스테이징)"
    echo "  3) prod (프로덕션)"
    read -p "선택 [1]: " env_choice
    case $env_choice in
        2) ENVIRONMENT="staging" ;;
        3) ENVIRONMENT="prod" ;;
        *) ENVIRONMENT="dev" ;;
    esac
    
    # AWS 리전
    echo "AWS 리전 선택:"
    echo "  1) us-east-1 (버지니아)"
    echo "  2) ap-northeast-2 (서울)"
    echo "  3) ap-northeast-1 (도쿄)"
    read -p "선택 [1]: " region_choice
    case $region_choice in
        2) AWS_REGION="ap-northeast-2" ;;
        3) AWS_REGION="ap-northeast-1" ;;
        *) AWS_REGION="us-east-1" ;;
    esac
    
    # 확인
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}설정 확인${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  프로젝트: $PROJECT_NAME"
    echo "  환경: $ENVIRONMENT"
    echo "  리전: $AWS_REGION"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    read -p "계속하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi
}

# 환경변수 파일 생성
setup_environment() {
    print_step "환경변수 설정 중..."
    
    # 백엔드 환경변수
    cd backend
    if [ ! -f .env.$ENVIRONMENT ]; then
        cp .env.example .env.$ENVIRONMENT
        
        # 기본값 설정
        sed -i.bak "s/SERVICE_NAME=.*/SERVICE_NAME=$PROJECT_NAME/" .env.$ENVIRONMENT
        sed -i.bak "s/ENVIRONMENT=.*/ENVIRONMENT=$ENVIRONMENT/" .env.$ENVIRONMENT
        sed -i.bak "s/AWS_REGION=.*/AWS_REGION=$AWS_REGION/" .env.$ENVIRONMENT
        rm .env.$ENVIRONMENT.bak
        
        print_success "백엔드 환경변수 파일 생성: .env.$ENVIRONMENT"
    else
        print_warning "백엔드 환경변수 파일이 이미 존재합니다"
    fi
    
    # 프론트엔드 환경변수
    cd ../1-frontend
    if [ ! -f .env.$ENVIRONMENT ]; then
        cat > .env.$ENVIRONMENT << EOF
# Frontend Environment Variables
VITE_APP_TITLE=$PROJECT_NAME
VITE_API_BASE_URL=https://api-$ENVIRONMENT.$PROJECT_NAME.com
VITE_WS_URL=wss://ws-$ENVIRONMENT.$PROJECT_NAME.com
VITE_ENVIRONMENT=$ENVIRONMENT
EOF
        print_success "프론트엔드 환경변수 파일 생성: .env.$ENVIRONMENT"
    else
        print_warning "프론트엔드 환경변수 파일이 이미 존재합니다"
    fi
    
    cd ..
}

# 백엔드 설정 및 배포
setup_backend() {
    print_step "백엔드 설정 중..."
    cd backend
    
    # Node 의존성 설치
    print_step "Node.js 패키지 설치 중..."
    npm install
    
    # Python 가상환경 설정
    print_step "Python 가상환경 설정 중..."
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # 테스트 실행
    print_step "테스트 실행 중..."
    pytest tests/unit/ -v || print_warning "일부 테스트 실패 (계속 진행)"
    
    # Lambda Layer 빌드
    print_step "Lambda Layer 빌드 중..."
    cd layers
    ./build.sh
    cd ..
    
    # 배포 여부 확인
    read -p "백엔드를 AWS에 배포하시겠습니까? (y/N): " deploy_backend
    if [[ $deploy_backend =~ ^[Yy]$ ]]; then
        print_step "백엔드 배포 중 ($ENVIRONMENT 환경)..."
        npx serverless deploy --stage $ENVIRONMENT --region $AWS_REGION
        
        # 배포 결과 저장
        npx serverless info --stage $ENVIRONMENT --region $AWS_REGION > deployment-info.txt
        print_success "백엔드 배포 완료!"
    else
        print_warning "백엔드 배포 건너뜀"
    fi
    
    cd ..
}

# 프론트엔드 설정
setup_frontend() {
    print_step "프론트엔드 설정 중..."
    cd 1-frontend
    
    # 의존성 설치
    print_step "프론트엔드 패키지 설치 중..."
    npm install
    
    # 빌드
    print_step "프론트엔드 빌드 중..."
    npm run build
    
    print_success "프론트엔드 설정 완료!"
    cd ..
}

# 인프라 배포 (CDK)
setup_infrastructure() {
    print_step "인프라 설정 확인 중..."
    
    if [ -d "3-deploy" ]; then
        cd 3-deploy
        
        read -p "CDK 인프라를 배포하시겠습니까? (y/N): " deploy_cdk
        if [[ $deploy_cdk =~ ^[Yy]$ ]]; then
            print_step "CDK 배포 준비 중..."
            npm install
            
            # CDK Bootstrap (첫 배포시)
            print_step "CDK Bootstrap 실행 중..."
            npx cdk bootstrap aws://$AWS_ACCOUNT_ID/$AWS_REGION || print_warning "Bootstrap 이미 완료됨"
            
            # CDK 배포
            print_step "CDK 스택 배포 중..."
            npx cdk deploy --all --require-approval never
            
            print_success "인프라 배포 완료!"
        else
            print_warning "인프라 배포 건너뜀"
        fi
        
        cd ..
    else
        print_warning "CDK 배포 폴더가 없습니다"
    fi
}

# 프로젝트 정보 출력
print_project_info() {
    print_step "프로젝트 설정 완료!"
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🎉 프로젝트 설정 완료${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n${GREEN}프로젝트 정보:${NC}"
    echo "  • 이름: $PROJECT_NAME"
    echo "  • 환경: $ENVIRONMENT"
    echo "  • 리전: $AWS_REGION"
    
    if [ -f "backend/deployment-info.txt" ]; then
        echo -e "\n${GREEN}백엔드 엔드포인트:${NC}"
        grep -E "(ServiceEndpoint|WebSocketUrl)" backend/deployment-info.txt | sed 's/^/  /'
    fi
    
    echo -e "\n${GREEN}다음 단계:${NC}"
    echo "  1. 백엔드 로그 확인:"
    echo "     cd backend && make logs STAGE=$ENVIRONMENT"
    echo ""
    echo "  2. 프론트엔드 실행:"
    echo "     cd 1-frontend && npm run dev"
    echo ""
    echo "  3. 환경변수 수정:"
    echo "     • backend/.env.$ENVIRONMENT"
    echo "     • 1-frontend/.env.$ENVIRONMENT"
    
    echo -e "\n${GREEN}유용한 명령어:${NC}"
    echo "  • 백엔드 테스트: cd backend && make test"
    echo "  • 백엔드 배포: cd backend && make deploy-$ENVIRONMENT"
    echo "  • 프론트엔드 빌드: cd 1-frontend && npm run build"
    echo "  • 로그 확인: cd backend && make logs"
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✨ Happy Coding!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 메인 실행 흐름
main() {
    clear
    print_logo
    
    print_step "Nexus 템플릿 설정을 시작합니다..."
    
    # 1. 사전 요구사항 체크
    check_prerequisites
    
    # 2. 프로젝트 정보 수집
    collect_project_info
    
    # 3. 환경변수 설정
    setup_environment
    
    # 4. 백엔드 설정
    setup_backend
    
    # 5. 프론트엔드 설정
    setup_frontend
    
    # 6. 인프라 배포
    setup_infrastructure
    
    # 7. 완료 정보 출력
    print_project_info
}

# 스크립트 실행
main "$@"