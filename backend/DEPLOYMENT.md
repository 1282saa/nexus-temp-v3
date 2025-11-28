# 🚀 Nexus Backend 배포 가이드

## 사전 준비

### 1. AWS 설정
```bash
# AWS CLI 설치 및 설정
aws configure
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY 입력
```

### 2. Node.js 의존성 설치
```bash
# package.json의 서버리스 플러그인 설치
npm install
```

### 3. Python 환경 설정
```bash
# 가상환경 생성 및 활성화
make setup
source venv/bin/activate
```

### 4. 환경변수 설정
```bash
# 환경별 설정 파일 생성
cp .env.example .env.dev
cp .env.example .env.staging  
cp .env.example .env.prod

# 각 파일 편집하여 실제 값 입력
```

## 배포 프로세스

### 개발 환경 배포

#### 방법 1: Makefile 사용 (권장)
```bash
make deploy-dev
```

#### 방법 2: npm 스크립트
```bash
npm run deploy:dev
```

#### 방법 3: Serverless CLI 직접 사용
```bash
serverless deploy --stage dev --region us-east-1
```

### 스테이징 환경 배포

```bash
# 테스트 실행 후 배포
make validate
make deploy-staging

# 또는
npm run deploy:staging
```

### 프로덕션 환경 배포

⚠️ **주의**: 프로덕션 배포는 신중하게!

```bash
# 1. 모든 테스트 통과 확인
make test

# 2. 스테이징 환경에서 검증
make deploy-staging
make logs STAGE=staging  # 로그 확인

# 3. 프로덕션 배포
make deploy-prod
# "production" 입력하여 확인
```

## 배포 후 확인

### 1. 서비스 정보 확인
```bash
# 배포된 엔드포인트 및 리소스 확인
serverless info --stage dev --verbose

# 또는
make info STAGE=dev
```

### 2. 로그 모니터링
```bash
# 실시간 로그 확인
make logs STAGE=dev

# 특정 함수 로그
serverless logs -f conversationApi --stage dev --tail
```

### 3. 함수 테스트
```bash
# Lambda 함수 직접 호출
serverless invoke -f conversationApi --stage dev --path tests/fixtures/sample_event.json
```

### 4. 메트릭 확인
```bash
# CloudWatch 메트릭
make metrics STAGE=dev
```

## 롤백

문제 발생 시 이전 버전으로 롤백:

```bash
# 이전 배포 목록 확인
serverless deploy list --stage prod

# 특정 타임스탬프로 롤백
serverless rollback --stage prod --timestamp 1234567890
```

## 스택 제거

더 이상 필요없는 환경 제거:

```bash
# 개발 환경 제거
make remove STAGE=dev

# 또는
serverless remove --stage dev
```

## 문제 해결

### 1. 배포 실패

#### IAM 권한 부족
```bash
# 필요한 권한 확인
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USER
```

#### Python 패키지 빌드 실패
```bash
# Docker를 사용한 빌드
serverless deploy --stage dev --docker
```

### 2. Lambda 함수 에러

#### 메모리 부족
```yaml
# serverless.yml에서 메모리 증가
functions:
  conversationApi:
    memorySize: 1024  # MB
```

#### 타임아웃
```yaml
# serverless.yml에서 타임아웃 증가
functions:
  conversationApi:
    timeout: 300  # seconds
```

### 3. DynamoDB 에러

#### 처리량 초과
```yaml
# serverless.yml에서 온디맨드로 변경
resources:
  Resources:
    ConversationsTable:
      Properties:
        BillingMode: PAY_PER_REQUEST
```

## 모니터링

### CloudWatch 대시보드
1. AWS Console → CloudWatch → Dashboards
2. Lambda 함수별 메트릭 확인
3. API Gateway 메트릭 확인
4. DynamoDB 메트릭 확인

### X-Ray 추적 (프로덕션)
```python
# 코드에 X-Ray 추적 추가
from aws_xray_sdk.core import xray_recorder

@xray_recorder.capture('process_message')
def process_message():
    pass
```

### 알람 설정
```yaml
# serverless.yml에 알람 추가
resources:
  Resources:
    ErrorAlarm:
      Type: AWS::CloudWatch::Alarm
      Properties:
        AlarmName: ${self:service}-errors-${self:provider.stage}
        MetricName: Errors
        Namespace: AWS/Lambda
        Threshold: 10
        Period: 300
```

## 보안 체크리스트

- [ ] 환경변수에 민감한 정보 없음
- [ ] API Gateway에 적절한 인증/인가
- [ ] DynamoDB 암호화 활성화
- [ ] CloudWatch 로그 보관 기간 설정
- [ ] IAM 역할 최소 권한 원칙
- [ ] VPC 설정 (필요시)
- [ ] Secrets Manager 사용 (API 키 등)

## 비용 최적화

### 1. Lambda
- 적절한 메모리 설정 (과도한 메모리는 비용 증가)
- ARM 아키텍처 사용 (20% 비용 절감)
- 예약 용량 구매 (안정적 트래픽)

### 2. DynamoDB
- 온디맨드 vs 프로비저닝 선택
- TTL 설정으로 오래된 데이터 자동 삭제
- 글로벌 보조 인덱스 최소화

### 3. API Gateway
- 캐싱 활성화
- 사용량 계획 설정

## 자동화 (CI/CD)

GitHub Actions 설정 (추후 추가):
```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to AWS
        run: |
          npm install
          serverless deploy --stage prod
```