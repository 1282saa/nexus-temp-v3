#!/bin/bash

# NEXUS 템플릿 시작 스크립트
# 개발자가 아니어도 쉽게 사용할 수 있는 메뉴 시스템

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 현재 디렉토리 저장
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 필수 도구 체크
check_prerequisites() {
    local missing_tools=()
    
    echo -e "${YELLOW}🔍 필수 도구 확인 중...${NC}"
    echo ""
    
    # AWS CLI 체크
    if command -v aws &> /dev/null; then
        echo -e "  ✅ AWS CLI: $(aws --version 2>&1 | cut -d' ' -f1)"
    else
        echo -e "  ❌ AWS CLI: 설치 필요"
        missing_tools+=("AWS CLI")
    fi
    
    # Node.js 체크
    if command -v node &> /dev/null; then
        echo -e "  ✅ Node.js: $(node --version)"
    else
        echo -e "  ❌ Node.js: 설치 필요"
        missing_tools+=("Node.js")
    fi
    
    # npm 체크
    if command -v npm &> /dev/null; then
        echo -e "  ✅ npm: $(npm --version)"
    else
        echo -e "  ❌ npm: 설치 필요"
        missing_tools+=("npm")
    fi
    
    # Python 체크
    if command -v python3 &> /dev/null; then
        echo -e "  ✅ Python: $(python3 --version 2>&1)"
    else
        echo -e "  ❌ Python3: 설치 필요"
        missing_tools+=("Python3")
    fi
    
    # AWS 인증 체크
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        echo -e "  ✅ AWS 인증: 계정 $ACCOUNT_ID"
    else
        echo -e "  ⚠️  AWS 인증: 설정 필요 (aws configure)"
    fi
    
    echo ""
    
    # 누락된 도구가 있으면 설치 안내
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}❌ 다음 도구들을 먼저 설치해주세요:${NC}"
        echo ""
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "AWS CLI")
                    echo "  📦 AWS CLI:"
                    echo "     Mac: brew install awscli"
                    echo "     설치 가이드: https://aws.amazon.com/cli/"
                    ;;
                "Node.js"|"npm")
                    echo "  📦 Node.js & npm:"
                    echo "     Mac: brew install node"
                    echo "     설치 가이드: https://nodejs.org/"
                    ;;
                "Python3")
                    echo "  📦 Python3:"
                    echo "     Mac: brew install python3"
                    echo "     설치 가이드: https://www.python.org/"
                    ;;
            esac
            echo ""
        done
        
        echo -e "${YELLOW}설치 후 다시 실행해주세요.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 모든 필수 도구가 준비되었습니다!${NC}"
    echo ""
    echo -e "${CYAN}Enter를 누르면 계속합니다...${NC}"
    read
}

# 로고 출력
show_logo() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║     ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗        ║"
    echo "║     ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝        ║"
    echo "║     ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗        ║"
    echo "║     ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║        ║"
    echo "║     ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║        ║"
    echo "║     ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝        ║"
    echo "║                                                           ║"
    echo "║            🤖 AI Chat Service Template System 🤖          ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 서비스 상태 확인
check_service_status() {
    if [ -f ".env.deploy" ]; then
        SERVICE_NAME=$(grep "^SERVICE_NAME=" .env.deploy | cut -d'=' -f2)
        if [ -n "$SERVICE_NAME" ]; then
            echo -e "${GREEN}✓ 현재 구성된 서비스: $SERVICE_NAME${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 아직 구성된 서비스가 없습니다.${NC}"
    fi
    echo ""
}

# 메인 메뉴
show_main_menu() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}메인 메뉴 - 원하시는 작업을 선택해주세요:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) 🚀 새 서비스 설정 시작 (처음 시작하기)"
    echo "  2) 🏗️  AWS 인프라 구축"
    echo "  3) 📦 서비스 배포"
    echo "  4) 🔧 유틸리티 도구"
    echo "  5) 📖 도움말"
    echo "  6) 🚪 종료"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# 설정 메뉴
setup_menu() {
    clear
    show_logo
    echo -e "${PURPLE}1. 서비스 설정${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) 새 서비스 구성 (대화형 설정)"
    echo "  2) 기본 설정으로 빠른 시작"
    echo "  3) 기존 설정 확인"
    echo "  4) 메인 메뉴로 돌아가기"
    echo ""
    
    read -p "선택: " choice
    
    case $choice in
        1)
            echo -e "\n${GREEN}새 서비스를 구성합니다...${NC}\n"
            bash 1-setup/configure.sh
            ;;
        2)
            echo -e "\n${GREEN}기본 설정으로 서비스를 구성합니다...${NC}\n"
            bash 1-setup/setup.sh
            ;;
        3)
            if [ -f ".env.deploy" ]; then
                echo -e "\n${GREEN}현재 설정:${NC}"
                cat .env.deploy
            else
                echo -e "\n${YELLOW}설정 파일이 없습니다.${NC}"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}잘못된 선택입니다.${NC}"
            ;;
    esac
    
    echo -e "\n${CYAN}Enter를 누르면 계속합니다...${NC}"
    read
}

# 인프라 메뉴
infrastructure_menu() {
    clear
    show_logo
    echo -e "${PURPLE}2. AWS 인프라 구축${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) 🎯 전체 인프라 한번에 구축 (권장)"
    echo "  2) 📝 개별 구성 요소 생성"
    echo "     - Lambda 함수"
    echo "     - API Gateway"
    echo "     - Cognito 사용자 풀"
    echo "  3) 🔍 인프라 상태 확인"
    echo "  4) 메인 메뉴로 돌아가기"
    echo ""
    
    read -p "선택: " choice
    
    case $choice in
        1)
            echo -e "\n${GREEN}전체 인프라를 구축합니다...${NC}\n"
            bash 2-infrastructure/create-infrastructure.sh
            ;;
        2)
            infrastructure_component_menu
            ;;
        3)
            echo -e "\n${GREEN}인프라 상태를 확인합니다...${NC}\n"
            check_infrastructure_status
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}잘못된 선택입니다.${NC}"
            ;;
    esac
    
    echo -e "\n${CYAN}Enter를 누르면 계속합니다...${NC}"
    read
}

# 인프라 개별 구성 요소 메뉴
infrastructure_component_menu() {
    clear
    show_logo
    echo -e "${PURPLE}인프라 개별 구성 요소${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) Lambda 함수 생성"
    echo "  2) API Gateway 생성"
    echo "  3) Cognito 사용자 풀 생성"
    echo "  4) 뒤로 가기"
    echo ""
    
    read -p "선택: " choice
    
    case $choice in
        1)
            echo -e "\n${GREEN}Lambda 함수를 생성합니다...${NC}\n"
            bash 2-infrastructure/create-lambda.sh
            ;;
        2)
            echo -e "\n${GREEN}API Gateway를 생성합니다...${NC}\n"
            bash 2-infrastructure/create-api-gateway.sh
            ;;
        3)
            echo -e "\n${GREEN}Cognito 사용자 풀을 생성합니다...${NC}\n"
            bash 2-infrastructure/create-cognito.sh
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}잘못된 선택입니다.${NC}"
            ;;
    esac
}

# 배포 메뉴
deploy_menu() {
    clear
    show_logo
    echo -e "${PURPLE}3. 서비스 배포${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) 🚀 전체 배포 (프론트엔드 + 백엔드)"
    echo "  2) 🌐 프론트엔드만 배포"
    echo "  3) ⚙️  백엔드만 배포"
    echo "  4) 🔄 변경사항 확인 후 배포"
    echo "  5) 메인 메뉴로 돌아가기"
    echo ""
    
    read -p "선택: " choice
    
    case $choice in
        1)
            echo -e "\n${GREEN}전체 서비스를 배포합니다...${NC}\n"
            bash 3-deploy/deploy.sh --all
            ;;
        2)
            echo -e "\n${GREEN}프론트엔드를 배포합니다...${NC}\n"
            bash 3-deploy/deploy-frontend.sh
            ;;
        3)
            echo -e "\n${GREEN}백엔드를 배포합니다...${NC}\n"
            bash 3-deploy/deploy-backend.sh
            ;;
        4)
            echo -e "\n${GREEN}변경사항을 확인하고 배포합니다...${NC}\n"
            bash 3-deploy/deploy.sh
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}잘못된 선택입니다.${NC}"
            ;;
    esac
    
    echo -e "\n${CYAN}Enter를 누르면 계속합니다...${NC}"
    read
}

# 유틸리티 메뉴
utilities_menu() {
    clear
    show_logo
    echo -e "${PURPLE}4. 유틸리티 도구${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) 🔄 환경 변수 파일 재생성"
    echo "  2) 📋 현재 설정 확인"
    echo "  3) 🗑️  배포 파일 정리"
    echo "  4) 📊 AWS 리소스 사용량 확인"
    echo "  5) 메인 메뉴로 돌아가기"
    echo ""
    
    read -p "선택: " choice
    
    case $choice in
        1)
            echo -e "\n${GREEN}환경 변수 파일을 재생성합니다...${NC}\n"
            bash 4-utilities/generate-env.sh
            ;;
        2)
            show_current_config
            ;;
        3)
            clean_deployment_files
            ;;
        4)
            check_aws_usage
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}잘못된 선택입니다.${NC}"
            ;;
    esac
    
    echo -e "\n${CYAN}Enter를 누르면 계속합니다...${NC}"
    read
}

# 도움말 표시
show_help() {
    clear
    show_logo
    echo -e "${PURPLE}📖 도움말${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}빠른 시작 가이드:${NC}"
    echo ""
    echo "1. 처음 시작하는 경우:"
    echo "   - '1. 새 서비스 설정 시작' 선택"
    echo "   - 서비스 이름과 설정 입력"
    echo ""
    echo "2. AWS 인프라 구축:"
    echo "   - '2. AWS 인프라 구축' > '전체 인프라 한번에 구축' 선택"
    echo "   - 자동으로 필요한 AWS 리소스가 생성됩니다"
    echo ""
    echo "3. 서비스 배포:"
    echo "   - '3. 서비스 배포' > '전체 배포' 선택"
    echo "   - 프론트엔드와 백엔드가 AWS에 배포됩니다"
    echo ""
    echo -e "${YELLOW}주의사항:${NC}"
    echo "- AWS CLI가 설치되어 있고 인증이 완료되어 있어야 합니다"
    echo "- Node.js 18 이상이 설치되어 있어야 합니다"
    echo "- 충분한 AWS 권한이 있어야 합니다"
    echo ""
    echo -e "${CYAN}추가 도움이 필요하면 README.md 파일을 참조하세요.${NC}"
    echo ""
    echo -e "${CYAN}Enter를 누르면 메인 메뉴로 돌아갑니다...${NC}"
    read
}

# 현재 설정 확인
show_current_config() {
    echo -e "\n${GREEN}현재 설정:${NC}"
    echo -e "${BLUE}─────────────────────────────────────${NC}"
    
    if [ -f ".env.deploy" ]; then
        echo -e "${YELLOW}배포 설정 (.env.deploy):${NC}"
        grep -E "^(SERVICE_NAME|STACK_SUFFIX|AWS_REGION)" .env.deploy
        echo ""
    fi
    
    if [ -f "frontend/.env" ]; then
        echo -e "${YELLOW}프론트엔드 설정 (frontend/.env):${NC}"
        grep -E "^VITE_API_BASE_URL|^VITE_COGNITO" frontend/.env | head -5
        echo ""
    fi
    
    if [ -f "backend/.env" ]; then
        echo -e "${YELLOW}백엔드 설정 (backend/.env):${NC}"
        grep -E "^TABLE_PREFIX|^API_GATEWAY" backend/.env | head -5
    fi
}

# 배포 파일 정리
clean_deployment_files() {
    echo -e "\n${YELLOW}다음 파일들을 삭제합니다:${NC}"
    echo "- frontend/dist/*"
    echo "- backend/lambda-deployment.zip"
    echo "- backend/deployment-info.txt"
    echo "- frontend/deployment-info.txt"
    echo ""
    
    read -p "계속하시겠습니까? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf frontend/dist/*
        rm -f backend/lambda-deployment.zip
        rm -f backend/deployment-info.txt
        rm -f frontend/deployment-info.txt
        echo -e "${GREEN}정리 완료!${NC}"
    else
        echo -e "${YELLOW}취소되었습니다.${NC}"
    fi
}

# AWS 리소스 사용량 확인
check_aws_usage() {
    echo -e "\n${GREEN}AWS 리소스 확인 중...${NC}\n"
    
    if [ -f ".env.deploy" ]; then
        source .env.deploy
        
        echo -e "${YELLOW}Lambda 함수:${NC}"
        aws lambda list-functions --query "Functions[?contains(FunctionName, '${SERVICE_NAME}')].FunctionName" --output table 2>/dev/null || echo "Lambda 함수 없음"
        
        echo -e "\n${YELLOW}API Gateway:${NC}"
        aws apigateway get-rest-apis --query "items[?contains(name, '${SERVICE_NAME}')].name" --output table 2>/dev/null || echo "REST API 없음"
        
        echo -e "\n${YELLOW}S3 버킷:${NC}"
        aws s3 ls | grep "${SERVICE_NAME}" || echo "S3 버킷 없음"
    else
        echo -e "${RED}설정 파일이 없습니다. 먼저 서비스를 구성하세요.${NC}"
    fi
}

# 인프라 상태 확인
check_infrastructure_status() {
    echo -e "${GREEN}인프라 상태 확인 중...${NC}\n"
    
    if [ -f ".env.deploy" ]; then
        source .env.deploy
        
        # Lambda 함수 확인
        echo -e "${YELLOW}Lambda 함수 상태:${NC}"
        for func in api-prompt api-usage api-conversation ws-connect ws-disconnect ws-message; do
            if aws lambda get-function --function-name "${SERVICE_NAME}-${STACK_SUFFIX}-${func}" >/dev/null 2>&1; then
                echo -e "  ✓ ${func}: ${GREEN}활성${NC}"
            else
                echo -e "  ✗ ${func}: ${RED}없음${NC}"
            fi
        done
        
        echo ""
        
        # API Gateway 확인
        echo -e "${YELLOW}API Gateway 상태:${NC}"
        if [ -f "frontend/.env" ]; then
            API_URL=$(grep "^VITE_API_BASE_URL=" frontend/.env | cut -d'=' -f2)
            if [ -n "$API_URL" ]; then
                echo -e "  ✓ REST API: ${GREEN}${API_URL}${NC}"
            fi
            
            WS_URL=$(grep "^VITE_WS_URL=" frontend/.env | cut -d'=' -f2)
            if [ -n "$WS_URL" ]; then
                echo -e "  ✓ WebSocket API: ${GREEN}${WS_URL}${NC}"
            fi
        fi
        
        echo ""
        
        # Cognito 확인
        echo -e "${YELLOW}Cognito 상태:${NC}"
        if [ -f "frontend/.env" ]; then
            POOL_ID=$(grep "^VITE_COGNITO_USER_POOL_ID=" frontend/.env | cut -d'=' -f2)
            if [ -n "$POOL_ID" ]; then
                echo -e "  ✓ User Pool: ${GREEN}${POOL_ID}${NC}"
            fi
        fi
    else
        echo -e "${RED}설정 파일이 없습니다. 먼저 서비스를 구성하세요.${NC}"
    fi
}

# 메인 루프
main() {
    while true; do
        show_logo
        check_service_status
        show_main_menu
        
        read -p "선택: " choice
        
        case $choice in
            1)
                setup_menu
                ;;
            2)
                infrastructure_menu
                ;;
            3)
                deploy_menu
                ;;
            4)
                utilities_menu
                ;;
            5)
                show_help
                ;;
            6)
                echo -e "\n${GREEN}프로그램을 종료합니다. 감사합니다!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}잘못된 선택입니다. 다시 선택해주세요.${NC}"
                sleep 2
                ;;
        esac
    done
}

# 프로그램 시작
# 처음 실행 시 필수 도구 체크
if [ ! -f ".nexus-prereq-checked" ]; then
    show_logo
    check_prerequisites
    touch .nexus-prereq-checked
fi

main