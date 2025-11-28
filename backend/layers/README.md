# Lambda Layers

Lambda 함수들이 공유하는 공통 라이브러리를 관리합니다.

## 🎯 목적

- **코드 중복 제거**: 모든 함수가 같은 라이브러리 공유
- **배포 크기 감소**: 각 함수의 크기를 줄임
- **버전 관리 용이**: 라이브러리 버전을 한 곳에서 관리

## 📦 포함된 라이브러리

### nexus-common-layer
- `boto3`, `botocore` - AWS SDK
- `python-dateutil` - 날짜/시간 처리
- `simplejson` - JSON 처리
- `urllib3` - HTTP 요청
- `python-json-logger` - 구조화된 로깅

## 🔧 빌드 방법

### 자동 빌드
```bash
# Makefile 사용
make build-layer

# 또는 직접 스크립트 실행
./build.sh
```

### 수동 빌드
```bash
# 1. 디렉토리 생성
mkdir -p python/lib/python3.11/site-packages

# 2. 의존성 설치
pip install --target python/lib/python3.11/site-packages -r requirements.txt

# 3. ZIP 파일 생성
zip -r9 nexus-common-layer.zip python/
```

## 📤 배포

### Serverless Framework 사용
```yaml
# serverless.yml에 정의됨
layers:
  commonLayer:
    path: layers
    name: ${self:service}-common-${self:provider.stage}
```

### AWS CLI 사용
```bash
aws lambda publish-layer-version \
    --layer-name nexus-common-layer \
    --zip-file fileb://nexus-common-layer.zip \
    --compatible-runtimes python3.11 \
    --compatible-architectures arm64
```

## 🏗️ 구조

```
layers/
├── requirements.txt      # Layer 의존성
├── build.sh             # 빌드 스크립트
├── python/              # 빌드된 라이브러리
│   └── lib/
│       └── python3.11/
│           └── site-packages/
│               ├── boto3/
│               ├── botocore/
│               └── ...
└── nexus-common-layer.zip  # 배포용 ZIP
```

## ⚠️ 주의사항

1. **크기 제한**: Lambda Layer는 최대 250MB (압축 해제 후)
2. **호환성**: Python 버전과 아키텍처(x86_64/arm64) 일치 필요
3. **경로**: 라이브러리는 반드시 `python/lib/pythonX.X/site-packages/`에 위치

## 🔄 업데이트

라이브러리 추가/업데이트 시:

1. `requirements.txt` 수정
2. `./build.sh` 실행
3. `serverless deploy` 또는 AWS CLI로 배포

## 💡 최적화 팁

- 불필요한 파일 제거 (`.pyc`, `__pycache__`, `.dist-info`)
- 필수 라이브러리만 포함
- 개발 의존성은 제외 (pytest, black 등)