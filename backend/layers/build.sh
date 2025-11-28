#!/bin/bash
# Lambda Layer 빌드 스크립트

set -e

echo "🔧 Lambda Layer 빌드 시작..."

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 변수 설정
LAYER_NAME="nexus-common-layer"
PYTHON_VERSION="python3.11"
ARCH="arm64"  # Graviton2 아키텍처

# 기존 빌드 디렉토리 정리
echo -e "${YELLOW}정리 중...${NC}"
rm -rf python/
rm -rf *.zip

# Python 디렉토리 생성
mkdir -p python/lib/${PYTHON_VERSION}/site-packages

# 의존성 설치
echo -e "${YELLOW}의존성 설치 중...${NC}"
pip install \
    --platform manylinux2014_aarch64 \
    --only-binary=:all: \
    --target python/lib/${PYTHON_VERSION}/site-packages \
    -r requirements.txt

# 불필요한 파일 제거 (크기 최적화)
echo -e "${YELLOW}최적화 중...${NC}"
find python -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find python -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find python -type f -name "*.pyc" -delete
find python -type f -name "*.pyo" -delete

# ZIP 파일 생성
echo -e "${YELLOW}패키징 중...${NC}"
zip -r9 ${LAYER_NAME}.zip python/

# 크기 확인
SIZE=$(ls -lh ${LAYER_NAME}.zip | awk '{print $5}')
echo -e "${GREEN}✅ Layer 빌드 완료!${NC}"
echo -e "📦 파일: ${LAYER_NAME}.zip"
echo -e "📏 크기: ${SIZE}"

# Lambda Layer 크기 제한 확인 (250MB)
SIZE_BYTES=$(stat -f%z ${LAYER_NAME}.zip 2>/dev/null || stat -c%s ${LAYER_NAME}.zip 2>/dev/null)
MAX_SIZE=$((250 * 1024 * 1024))

if [ $SIZE_BYTES -gt $MAX_SIZE ]; then
    echo -e "${RED}⚠️  경고: Layer 크기가 250MB를 초과합니다!${NC}"
else
    echo -e "${GREEN}✅ Layer 크기 확인 완료${NC}"
fi

echo -e "${GREEN}🎉 빌드 성공!${NC}"