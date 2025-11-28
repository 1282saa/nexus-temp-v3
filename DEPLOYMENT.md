# Nexus 배포 완전 가이드

이 문서는 Nexus 템플릿의 환경 설정부터 AWS 배포까지 전체 과정을 다룹니다.

## 목차

1. [환경 설정](#1-환경-설정)
2. [사전 준비](#2-사전-준비)
3. [백엔드 배포](#3-백엔드-배포)
4. [프론트엔드 배포](#4-프론트엔드-배포)
5. [배포 검증](#5-배포-검증)
6. [업데이트 및 관리](#6-업데이트-및-관리)
7. [문제 해결](#7-문제-해결)
8. [리소스 정리](#8-리소스-정리)

---

## 1. 환경 설정

### 보안 안내

**중요: 실제 API 키, 비밀번호, 토큰 등의 민감한 정보를 Git에 커밋하지 마세요.**

커밋 가능한 파일:
- `.env.template` - 템플릿만 포함

커밋 금지 파일:
- `.env` - 실제 값 포함
- `config.json` - 실제 설정 포함

### 환경 변수 파일 생성

#### 백엔드 환경 설정
```bash
cd backend
cp .env.template .env
nano .env  # 실제 값 입력
```

필수 설정 항목 (실제 값 입력 필요):

| 항목 | 설명 | 예시 |
|-----|-----|-----|
| COGNITO_USER_POOL_ID | Cognito User Pool ID | us-east-1_XXXXXXXXX |
| COGNITO_CLIENT_ID | Cognito App Client ID | 26자리 영숫자 조합 |
| SERVICE_NAME | 서비스 이름 | nexus-backend |
| STAGE | 배포 환경 | dev, staging, prod |

#### 프론트엔드 환경 설정
```bash
cd frontend
cp .env.template .env
nano .env  # 백엔드 배포 후 얻은 URL 입력
```

필수 설정 항목 (백엔드 배포 후 얻은 URL 입력):

| 항목 | 설명 | 예시 |
|-----|-----|-----|
| VITE_API_BASE_URL | REST API URL | https://xxxxx.execute-api.us-east-1.amazonaws.com/dev |
| VITE_WS_URL | WebSocket URL | wss://yyyyy.execute-api.us-east-1.amazonaws.com/dev |
| VITE_COGNITO_USER_POOL_ID | Cognito User Pool ID | 백엔드와 동일 |
| VITE_COGNITO_CLIENT_ID | Cognito App Client ID | 백엔드와 동일 |
| VITE_ADMIN_EMAIL | 관리자 이메일 | admin@yourcompany.com |
| VITE_COMPANY_DOMAIN | 회사 도메인 | @yourcompany.com |

### AWS Cognito 설정

#### 방법 1: AWS 콘솔 사용 (비개발자 추천)

1. AWS 콘솔 접속: https://console.aws.amazon.com
2. Cognito 서비스 검색
3. "Create user pool" 클릭
4. 설정:
   - Authentication providers: Cognito user pool
   - Sign-in options: Email
   - Password policy: 기본값 사용
   - Multi-factor authentication: 선택사항
5. User pool 생성 후 Pool ID 복사
6. App integration 탭에서 "Create app client"
7. Public client 선택 후 Client ID 복사

#### 방법 2: AWS CLI 사용 (개발자용)

1. User Pool 생성:
```bash
aws cognito-idp create-user-pool \
  --pool-name "nexus-users" \
  --policies "PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true}" \
  --auto-verified-attributes email
```

2. 출력된 User Pool ID 저장 (us-east-1_XXXXXXXXX 형식)

3. App Client 생성:
```bash
aws cognito-idp create-user-pool-client \
  --user-pool-id [위에서 얻은 Pool ID] \
  --client-name "nexus-web-client" \
  --explicit-auth-flows "ALLOW_USER_PASSWORD_AUTH" "ALLOW_REFRESH_TOKEN_AUTH"
```

4. 출력된 Client ID 저장

---

## 2. 사전 준비

### 필수 도구 설치

```bash
# Node.js 18+ 확인
node --version

# Python 3.11 확인
python3 --version

# AWS CLI 설치 확인
aws --version

# Serverless Framework 설치
npm install -g serverless
```

### AWS 자격 증명 설정

```bash
aws configure
# AWS Access Key ID 입력
# AWS Secret Access Key 입력
# Default region: us-east-1
# Default output format: json
```

---

## 3. 백엔드 배포

### 3.1 백엔드 디렉토리 이동
```bash
cd backend
```

### 3.2 Python 가상 환경 설정
```bash
# 가상 환경 생성
python3 -m venv venv

# 가상 환경 활성화 (Mac/Linux)
source venv/bin/activate

# 가상 환경 활성화 (Windows)
# venv\Scripts\activate
```

### 3.3 의존성 설치
```bash
pip install -r requirements.txt
```

### 3.4 Serverless 플러그인 설치
```bash
npm install
```

### 3.5 배포 실행
```bash
serverless deploy --stage dev --region us-east-1
```

### 3.6 배포 결과 저장
배포 완료 후 출력되는 엔드포인트를 기록:
- REST API URL: `https://xxxxx.execute-api.us-east-1.amazonaws.com/dev`
- WebSocket URL: `wss://yyyyy.execute-api.us-east-1.amazonaws.com/dev`

---

## 4. 프론트엔드 배포

### 4.1 프론트엔드 디렉토리 이동
```bash
cd ../frontend
```

### 4.2 환경 변수 업데이트
백엔드 배포에서 얻은 URL을 `.env` 파일에 입력

### 4.3 의존성 설치
```bash
npm install
```

### 4.4 프론트엔드 빌드
```bash
npm run build
```

### 4.5 S3 버킷 생성
```bash
# 고유한 버킷 이름 생성 (타임스탬프 사용)
BUCKET_NAME="nexus-frontend-$(date +%s)"
echo "S3 버킷 이름: $BUCKET_NAME"

# 버킷 생성
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region us-east-1
```

### 4.6 S3 정적 웹사이트 호스팅 설정
```bash
# 정적 웹사이트 호스팅 활성화
aws s3 website s3://$BUCKET_NAME \
  --index-document index.html \
  --error-document error.html

# 퍼블릭 액세스 차단 해제
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

### 4.7 S3 버킷 정책 설정
```bash
# 버킷 정책 파일 생성
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

# 정책 적용
aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file:///tmp/bucket-policy.json
```

### 4.8 빌드 파일 업로드
```bash
# 모든 파일 업로드 (index.html 제외)
aws s3 sync dist/ s3://$BUCKET_NAME \
  --delete \
  --cache-control max-age=31536000,public \
  --exclude index.html

# index.html은 캐시하지 않도록 별도 업로드
aws s3 cp dist/index.html s3://$BUCKET_NAME/index.html \
  --cache-control max-age=0,no-cache,no-store,must-revalidate
```

### 4.9 CloudFront 배포 생성
```bash
# CloudFront 설정 파일 생성
cat > /tmp/cloudfront-config.json << EOF
{
    "CallerReference": "nexus-$(date +%s)",
    "Comment": "Nexus Frontend Distribution",
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 7,
            "Items": ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        },
        "Compress": true,
        "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
        "ResponseHeadersPolicyId": "67f7725c-6f97-4210-82d7-5512b31e9d03"
    },
    "CustomErrorResponses": {
        "Quantity": 2,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 10
            },
            {
                "ErrorCode": 403,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 10
            }
        ]
    },
    "Enabled": true,
    "HttpVersion": "http2"
}
EOF

# CloudFront 배포 생성
aws cloudfront create-distribution \
  --distribution-config file:///tmp/cloudfront-config.json
```

---

## 5. 배포 검증

### 5.1 CloudFront 배포 상태 확인
```bash
# CloudFront 배포 상태 확인 (15-30분 소요)
aws cloudfront get-distribution --id [Distribution-ID] \
  --query 'Distribution.Status'
```

### 5.2 웹사이트 접속 테스트

체크리스트:
1. CloudFront URL로 접속 (예: https://d1234567890.cloudfront.net)
2. 로그인 페이지가 정상적으로 표시되는지 확인
3. 회원가입 진행:
   - 이메일 주소 입력
   - 비밀번호 설정 (대소문자, 숫자 포함 8자 이상)
   - 이메일 인증 코드 확인
4. 로그인 테스트
5. 채팅 기능 테스트:
   - 메시지 입력 및 전송
   - AI 응답이 실시간으로 스트리밍되는지 확인
   - 대화 기록이 저장되는지 확인

### 5.3 백엔드 API 테스트
```bash
# API 상태 확인
curl https://xxxxx.execute-api.us-east-1.amazonaws.com/dev/health
```

---

## 6. 업데이트 및 관리

### 백엔드 업데이트
```bash
cd backend
serverless deploy --stage dev --region us-east-1
```

### 프론트엔드 업데이트
```bash
cd frontend

# 빌드
npm run build

# S3에 업로드
aws s3 sync dist/ s3://[버킷이름] --delete

# CloudFront 캐시 무효화
aws cloudfront create-invalidation \
  --distribution-id [Distribution-ID] \
  --paths "/*"
```

### 환경별 설정

#### 개발 환경 (dev)
```bash
STAGE=dev
VITE_SERVICE_TYPE=development
VITE_USE_MOCK=false
```

#### 스테이징 환경 (staging)
```bash
STAGE=staging
VITE_SERVICE_TYPE=staging
VITE_USE_MOCK=false
```

#### 프로덕션 환경 (production)
```bash
STAGE=prod
VITE_SERVICE_TYPE=production
VITE_USE_MOCK=false
```

---

## 7. 문제 해결

### CloudFront 접속 오류
- 배포 상태가 "Deployed"인지 확인 (15-30분 소요)
- S3 버킷 정책이 올바른지 확인

### API 연결 오류
- `.env` 파일의 API URL이 정확한지 확인
- CORS 설정 확인
- Lambda 함수 로그 확인: AWS CloudWatch

### 인증 오류
- Cognito User Pool ID와 Client ID 확인
- Region이 올바른지 확인 (기본: us-east-1)
- App Client의 인증 흐름 설정 확인

### 환경 변수가 적용되지 않을 때
```bash
# 프론트엔드 재시작
npm run dev

# 백엔드 재배포
serverless deploy --stage dev
```

---

## 8. 리소스 정리

테스트 후 리소스를 삭제하려면:

### 백엔드 삭제
```bash
cd backend
serverless remove --stage dev --region us-east-1
```

### CloudFront 삭제
```bash
# CloudFront 비활성화 (먼저 disable 필요)
aws cloudfront update-distribution \
  --id [Distribution-ID] \
  --if-match [ETag] \
  --distribution-config file:///tmp/disable-config.json

# 비활성화 완료 후 삭제
aws cloudfront delete-distribution \
  --id [Distribution-ID] \
  --if-match [ETag]
```

### S3 버킷 삭제
```bash
# 버킷 비우기
aws s3 rm s3://[버킷이름] --recursive

# 버킷 삭제
aws s3api delete-bucket --bucket [버킷이름]
```

---

## 보안 권장사항

1. **환경 변수 관리**
   - AWS Systems Manager Parameter Store 사용 고려
   - AWS Secrets Manager로 민감한 정보 관리
   
2. **접근 제어**
   - IAM 역할 최소 권한 원칙 적용
   - API Gateway에 API 키 또는 WAF 적용
   
3. **모니터링**
   - CloudWatch 알람 설정
   - 비정상적인 API 호출 감지

## 프로덕션 배포 체크리스트

- [ ] 모든 `.env` 파일이 `.gitignore`에 포함되어 있는지 확인
- [ ] 프로덕션용 Cognito User Pool 별도 생성
- [ ] 강력한 비밀번호 정책 설정
- [ ] MFA(다중 인증) 활성화 고려
- [ ] CloudFront 사용자 정의 도메인 설정
- [ ] HTTPS 인증서 설정
- [ ] CORS 설정 확인 (특정 도메인만 허용)

---

## 요약

1. **환경 설정**: `.env.template` 파일을 복사하여 실제 값 입력
2. **백엔드 배포**: Serverless Framework로 Lambda, API Gateway, DynamoDB 배포
3. **프론트엔드 빌드**: React 앱을 프로덕션 빌드
4. **S3 업로드**: 정적 파일을 S3 버킷에 호스팅
5. **CloudFront 배포**: CDN을 통한 글로벌 배포
6. **검증**: 모든 기능이 정상 작동하는지 확인

이 가이드를 따라하면 Nexus 템플릿을 AWS에 완전히 배포할 수 있습니다.