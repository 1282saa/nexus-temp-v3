#!/bin/bash

# NEXUS TEMPLATE - Cognito User Pool 생성 스크립트
# 템플릿 버전: 2.0.0

set -e

# AWS CLI 경로 설정
export PATH="/opt/homebrew/bin:$PATH"

# 환경변수 로드
if [ ! -f ".env.deploy" ]; then
    echo "❌ .env.deploy 파일이 없습니다."
    exit 1
fi

source .env.deploy

echo "========================================="
echo "   🔐 Cognito User Pool 생성"
echo "========================================="
echo ""
echo "서비스: ${SERVICE_NAME}"
echo "환경: ${STACK_SUFFIX}"
echo ""

USER_POOL_NAME="${SERVICE_NAME}-users-${STACK_SUFFIX}"
CLIENT_NAME="${SERVICE_NAME}-web-client-${STACK_SUFFIX}"

# User Pool 확인/생성
echo "👤 User Pool 확인 중..."
EXISTING_POOL=$(aws cognito-idp list-user-pools --max-results 60 --region ${AWS_REGION} \
    --query "UserPools[?Name=='${USER_POOL_NAME}'].Id" --output text 2>/dev/null || echo "")

if [ ! -z "${EXISTING_POOL}" ]; then
    USER_POOL_ID=${EXISTING_POOL}
    echo "   ✅ User Pool 존재함: ${USER_POOL_ID}"
else
    echo "   🔄 User Pool 생성 중..."
    
    # User Pool 설정
    USER_POOL_CONFIG=$(cat <<EOF
{
    "Policies": {
        "PasswordPolicy": {
            "MinimumLength": 8,
            "RequireUppercase": true,
            "RequireLowercase": true,
            "RequireNumbers": true,
            "RequireSymbols": false
        }
    },
    "AutoVerifiedAttributes": ["email"],
    "UsernameAttributes": ["email"],
    "MfaConfiguration": "OFF",
    "EmailConfiguration": {
        "EmailSendingAccount": "COGNITO_DEFAULT"
    },
    "AdminCreateUserConfig": {
        "AllowAdminCreateUserOnly": false
    },
    "AccountRecoverySetting": {
        "RecoveryMechanisms": [
            {
                "Priority": 1,
                "Name": "verified_email"
            }
        ]
    },
    "Schema": [
        {
            "Name": "email",
            "AttributeDataType": "String",
            "Required": true,
            "Mutable": true
        },
        {
            "Name": "name",
            "AttributeDataType": "String",
            "Required": false,
            "Mutable": true
        }
    ]
}
EOF
    )
    
    # User Pool 생성
    USER_POOL_ID=$(aws cognito-idp create-user-pool \
        --pool-name ${USER_POOL_NAME} \
        --cli-input-json "${USER_POOL_CONFIG}" \
        --region ${AWS_REGION} \
        --query 'UserPool.Id' \
        --output text)
    
    echo "   ✅ User Pool 생성 완료: ${USER_POOL_ID}"
fi

# User Pool Client 확인/생성
echo ""
echo "📱 User Pool Client 확인 중..."

# 기존 Client 확인
EXISTING_CLIENTS=$(aws cognito-idp list-user-pool-clients \
    --user-pool-id ${USER_POOL_ID} \
    --region ${AWS_REGION} \
    --query "UserPoolClients[?ClientName=='${CLIENT_NAME}'].ClientId" \
    --output text 2>/dev/null || echo "")

if [ ! -z "${EXISTING_CLIENTS}" ]; then
    CLIENT_ID=${EXISTING_CLIENTS}
    echo "   ✅ Client 존재함: ${CLIENT_ID}"
else
    echo "   🔄 Client 생성 중..."
    
    # Client 생성
    CLIENT_ID=$(aws cognito-idp create-user-pool-client \
        --user-pool-id ${USER_POOL_ID} \
        --client-name ${CLIENT_NAME} \
        --generate-secret false \
        --refresh-token-validity 30 \
        --access-token-validity 60 \
        --id-token-validity 60 \
        --token-validity-units \
            AccessToken=minutes \
            IdToken=minutes \
            RefreshToken=days \
        --explicit-auth-flows \
            ALLOW_USER_PASSWORD_AUTH \
            ALLOW_REFRESH_TOKEN_AUTH \
            ALLOW_USER_SRP_AUTH \
        --supported-identity-providers COGNITO \
        --allowed-o-auth-flows-user-pool-client false \
        --prevent-user-existence-errors ENABLED \
        --region ${AWS_REGION} \
        --query 'UserPoolClient.ClientId' \
        --output text)
    
    echo "   ✅ Client 생성 완료: ${CLIENT_ID}"
fi

# 관리자 사용자 생성 (옵션)
if [ ! -z "${ADMIN_EMAIL}" ]; then
    echo ""
    echo "👑 관리자 계정 확인 중..."
    
    # 사용자 존재 확인
    USER_EXISTS=$(aws cognito-idp admin-get-user \
        --user-pool-id ${USER_POOL_ID} \
        --username ${ADMIN_EMAIL} \
        --region ${AWS_REGION} >/dev/null 2>&1 && echo "true" || echo "false")
    
    if [ "${USER_EXISTS}" = "true" ]; then
        echo "   ✅ 관리자 계정 존재함: ${ADMIN_EMAIL}"
    else
        echo "   🔄 관리자 계정 생성 중..."
        
        # 임시 비밀번호 생성
        TEMP_PASSWORD="Temp@${RANDOM}2024"
        
        # 사용자 생성
        aws cognito-idp admin-create-user \
            --user-pool-id ${USER_POOL_ID} \
            --username ${ADMIN_EMAIL} \
            --user-attributes Name=email,Value=${ADMIN_EMAIL} Name=email_verified,Value=true \
            --temporary-password "${TEMP_PASSWORD}" \
            --message-action SUPPRESS \
            --region ${AWS_REGION} >/dev/null
        
        echo "   ✅ 관리자 계정 생성 완료"
        echo ""
        echo "   ⚠️  임시 비밀번호: ${TEMP_PASSWORD}"
        echo "   첫 로그인 시 비밀번호 변경이 필요합니다."
    fi
fi

# .env.deploy 파일 업데이트
echo ""
echo "📝 .env.deploy 파일 업데이트 중..."
sed -i.bak "s|COGNITO_USER_POOL_ID=.*|COGNITO_USER_POOL_ID=${USER_POOL_ID}|" .env.deploy
sed -i.bak "s|COGNITO_CLIENT_ID=.*|COGNITO_CLIENT_ID=${CLIENT_ID}|" .env.deploy
rm -f .env.deploy.bak

# frontend/.env 파일 업데이트
if [ -f "frontend/.env" ]; then
    echo "📝 frontend/.env 파일 업데이트 중..."
    sed -i.bak "s|\${COGNITO_USER_POOL_ID}|${USER_POOL_ID}|" frontend/.env
    sed -i.bak "s|\${COGNITO_CLIENT_ID}|${CLIENT_ID}|" frontend/.env
    rm -f frontend/.env.bak
fi

# config.json 업데이트
if [ -f "config.json" ] && command -v jq &> /dev/null; then
    echo "📝 config.json 파일 업데이트 중..."
    jq ".cognito.userPoolId = \"${USER_POOL_ID}\" | .cognito.clientId = \"${CLIENT_ID}\"" config.json > config.json.tmp
    mv config.json.tmp config.json
fi

echo ""
echo "========================================="
echo "   ✅ Cognito 설정 완료"
echo "========================================="
echo ""
echo "🔐 Cognito User Pool:"
echo "   Pool ID: ${USER_POOL_ID}"
echo "   Client ID: ${CLIENT_ID}"
echo "   리전: ${AWS_REGION}"
echo ""
echo "📋 인증 설정:"
echo "   - 이메일 로그인 활성화"
echo "   - 비밀번호 정책: 8자 이상, 대소문자+숫자"
echo "   - 토큰 유효기간: Access 60분, Refresh 30일"
echo ""
if [ ! -z "${ADMIN_EMAIL}" ]; then
    echo "👑 관리자 계정:"
    echo "   이메일: ${ADMIN_EMAIL}"
fi
echo ""
echo "💡 환경변수 파일이 자동 업데이트되었습니다:"
echo "   - .env.deploy"
echo "   - frontend/.env"
echo "   - config.json"
echo ""