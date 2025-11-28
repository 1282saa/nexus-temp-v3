# Nexus Backend Makefile
# 로컬 개발 및 배포 자동화

# 변수 설정
PYTHON := python3
PIP := pip3
VENV := venv
STAGE ?= dev
REGION ?= us-east-1
SERVICE_NAME ?= nexus-backend

# 색상 출력
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help
help: ## 도움말 표시
	@echo "$(BLUE)Nexus Backend 명령어$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

.PHONY: setup
setup: ## 초기 개발 환경 설정
	@echo "$(YELLOW)🔧 개발 환경 설정 중...$(NC)"
	$(PYTHON) -m venv $(VENV)
	. $(VENV)/bin/activate && $(PIP) install --upgrade pip
	. $(VENV)/bin/activate && $(PIP) install -r requirements-dev.txt
	@echo "$(GREEN)✅ 설정 완료! 'source venv/bin/activate'로 가상환경 활성화$(NC)"

.PHONY: install
install: ## 프로덕션 의존성 설치
	@echo "$(YELLOW)📦 의존성 설치 중...$(NC)"
	. $(VENV)/bin/activate && $(PIP) install -r requirements.txt
	@echo "$(GREEN)✅ 설치 완료$(NC)"

.PHONY: install-dev
install-dev: ## 개발 의존성 설치
	@echo "$(YELLOW)📦 개발 의존성 설치 중...$(NC)"
	. $(VENV)/bin/activate && $(PIP) install -r requirements-dev.txt
	@echo "$(GREEN)✅ 설치 완료$(NC)"

.PHONY: clean
clean: ## 캐시 및 임시 파일 정리
	@echo "$(YELLOW)🧹 정리 중...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name ".coverage" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ 정리 완료$(NC)"

.PHONY: format
format: ## 코드 포맷팅 (black, isort)
	@echo "$(YELLOW)✨ 코드 포맷팅 중...$(NC)"
	. $(VENV)/bin/activate && black . --exclude venv
	. $(VENV)/bin/activate && isort . --skip venv
	@echo "$(GREEN)✅ 포맷팅 완료$(NC)"

.PHONY: lint
lint: ## 코드 린팅 (flake8, pylint)
	@echo "$(YELLOW)🔍 코드 검사 중...$(NC)"
	. $(VENV)/bin/activate && flake8 . --exclude=venv,tests --max-line-length=120
	. $(VENV)/bin/activate && pylint handlers services utils config --ignore=venv,tests || true
	@echo "$(GREEN)✅ 린팅 완료$(NC)"

.PHONY: type-check
type-check: ## 타입 체크 (mypy)
	@echo "$(YELLOW)🔍 타입 검사 중...$(NC)"
	. $(VENV)/bin/activate && mypy . --ignore-missing-imports --exclude venv
	@echo "$(GREEN)✅ 타입 체크 완료$(NC)"

.PHONY: test
test: ## 테스트 실행
	@echo "$(YELLOW)🧪 테스트 실행 중...$(NC)"
	. $(VENV)/bin/activate && pytest tests/ -v --cov=. --cov-report=term-missing
	@echo "$(GREEN)✅ 테스트 완료$(NC)"

.PHONY: test-unit
test-unit: ## 단위 테스트만 실행
	@echo "$(YELLOW)🧪 단위 테스트 실행 중...$(NC)"
	. $(VENV)/bin/activate && pytest tests/unit/ -v
	@echo "$(GREEN)✅ 단위 테스트 완료$(NC)"

.PHONY: test-integration
test-integration: ## 통합 테스트만 실행
	@echo "$(YELLOW)🧪 통합 테스트 실행 중...$(NC)"
	. $(VENV)/bin/activate && pytest tests/integration/ -v
	@echo "$(GREEN)✅ 통합 테스트 완료$(NC)"

.PHONY: validate
validate: clean format lint type-check test ## 전체 검증 (포맷, 린트, 타입, 테스트)
	@echo "$(GREEN)✅ 모든 검증 완료!$(NC)"

.PHONY: config-check
config-check: ## 현재 설정 확인
	@echo "$(BLUE)📋 현재 설정:$(NC)"
	@echo "  STAGE: $(STAGE)"
	@echo "  REGION: $(REGION)"
	@echo "  SERVICE_NAME: $(SERVICE_NAME)"
	@. $(VENV)/bin/activate && python -c "from config.settings import settings; print(f'  TABLE_PREFIX: {settings.TABLE_PREFIX}'); print(f'  TABLE_SUFFIX: {settings.TABLE_SUFFIX}')"

.PHONY: local-api
local-api: ## 로컬 API 서버 실행 (개발용)
	@echo "$(YELLOW)🚀 로컬 API 서버 시작...$(NC)"
	@echo "$(BLUE)API: http://localhost:3000$(NC)"
	. $(VENV)/bin/activate && ENVIRONMENT=dev LOG_LEVEL=DEBUG python -m pytest tests/fixtures/local_server.py

.PHONY: deploy-dev
deploy-dev: validate ## 개발 환경 배포
	@echo "$(YELLOW)🚀 개발 환경 배포 중...$(NC)"
	@echo "$(BLUE)환경: dev, 리전: $(REGION)$(NC)"
	npx serverless deploy --stage dev --region $(REGION)
	@echo "$(GREEN)✅ 개발 환경 배포 완료$(NC)"

.PHONY: deploy-staging
deploy-staging: validate ## 스테이징 환경 배포
	@echo "$(YELLOW)🚀 스테이징 환경 배포 중...$(NC)"
	@echo "$(BLUE)환경: staging, 리전: $(REGION)$(NC)"
	@read -p "스테이징 배포를 진행하시겠습니까? (y/N): " confirm && [ "$$confirm" = "y" ]
	npx serverless deploy --stage staging --region $(REGION)
	@echo "$(GREEN)✅ 스테이징 환경 배포 완료$(NC)"

.PHONY: deploy-prod
deploy-prod: ## 프로덕션 환경 배포 (주의!)
	@echo "$(RED)⚠️  프로덕션 배포 - 주의 필요!$(NC)"
	@echo "$(BLUE)환경: prod, 리전: ap-northeast-2$(NC)"
	@read -p "정말로 프로덕션에 배포하시겠습니까? 'production'을 입력하세요: " confirm && [ "$$confirm" = "production" ]
	npx serverless deploy --stage prod --region ap-northeast-2
	@echo "$(GREEN)✅ 프로덕션 환경 배포 완료$(NC)"

.PHONY: remove
remove: ## 배포된 스택 제거
	@echo "$(RED)⚠️  스택 제거: $(STAGE)$(NC)"
	@read -p "$(STAGE) 스택을 제거하시겠습니까? (y/N): " confirm && [ "$$confirm" = "y" ]
	npx serverless remove --stage $(STAGE) --region $(REGION)
	@echo "$(GREEN)✅ 스택 제거 완료$(NC)"

.PHONY: logs
logs: ## CloudWatch 로그 확인
	@echo "$(BLUE)📋 CloudWatch 로그 ($(STAGE))$(NC)"
	npx serverless logs --function conversationApi --stage $(STAGE) --region $(REGION) --tail

.PHONY: logs-all
logs-all: ## 모든 함수의 로그 확인
	@echo "$(BLUE)📋 모든 함수 로그 ($(STAGE))$(NC)"
	npx serverless logs --stage $(STAGE) --region $(REGION) --tail

.PHONY: invoke
invoke: ## Lambda 함수 직접 호출 (테스트)
	@echo "$(YELLOW)⚡ Lambda 함수 호출 중...$(NC)"
	npx serverless invoke --function conversationApi --stage $(STAGE) --region $(REGION) --path tests/fixtures/sample_event.json

.PHONY: package
package: ## 배포 패키지 생성 (배포 없이)
	@echo "$(YELLOW)📦 배포 패키지 생성 중...$(NC)"
	npx serverless package --stage $(STAGE) --region $(REGION)
	@echo "$(GREEN)✅ 패키지 생성 완료 (.serverless/ 폴더 확인)$(NC)"

.PHONY: info
info: ## 배포된 서비스 정보 확인
	@echo "$(BLUE)ℹ️  서비스 정보 ($(STAGE))$(NC)"
	npx serverless info --stage $(STAGE) --region $(REGION) --verbose

.PHONY: metrics
metrics: ## CloudWatch 메트릭 확인
	@echo "$(BLUE)📊 메트릭 ($(STAGE))$(NC)"
	npx serverless metrics --stage $(STAGE) --region $(REGION)

.PHONY: requirements
requirements: ## requirements.txt 업데이트
	@echo "$(YELLOW)📝 requirements.txt 업데이트 중...$(NC)"
	. $(VENV)/bin/activate && pip freeze | grep -v pkg-resources > requirements-freeze.txt
	@echo "$(GREEN)✅ requirements-freeze.txt 생성 완료$(NC)"

# Docker 관련 명령어 제거 (Serverless Framework 사용)
# Docker가 필요한 경우:
# - serverless deploy --docker 옵션 사용
# - Lambda Layer 빌드 시 layers/build.sh 사용

.PHONY: all
all: setup install validate ## 전체 설정 및 검증