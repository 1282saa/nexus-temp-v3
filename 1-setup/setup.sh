#!/bin/bash

# ========================================
# NEXUS TEMPLATE SETUP SCRIPT
# ========================================
# This script helps you set up a new service from the template

set -e

echo "========================================="
echo "   🚀 NEXUS TEMPLATE SETUP WIZARD"
echo "========================================="
echo ""

# Check if .env.local exists
if [ -f ".env.local" ]; then
    echo "⚠️  .env.local already exists. Loading existing configuration..."
    source .env.local
else
    echo "📝 Let's configure your new service!"
    echo ""
    
    # Service Name
    read -p "Enter service name (e.g., 'my-app'): " SERVICE_NAME
    SERVICE_NAME=${SERVICE_NAME:-my-app}
    
    # Stack Suffix
    read -p "Enter stack suffix (e.g., 'prod', 'dev', 'staging'): " STACK_SUFFIX
    STACK_SUFFIX=${STACK_SUFFIX:-prod}
    
    # Environment
    read -p "Enter environment (production/development/staging): " ENVIRONMENT
    ENVIRONMENT=${ENVIRONMENT:-production}
    
    # Custom Domain
    read -p "Enter custom domain (e.g., 'app.example.com'): " CUSTOM_DOMAIN
    CUSTOM_DOMAIN=${CUSTOM_DOMAIN:-app.example.com}
    
    # AWS Region
    read -p "Enter AWS region (default: us-east-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-us-east-1}
    
    # AWS Account ID
    read -p "Enter AWS Account ID: " AWS_ACCOUNT_ID
    
    # Admin Email
    read -p "Enter admin email: " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
    
    # Company Domain
    read -p "Enter company domain (e.g., '@example.com'): " COMPANY_DOMAIN
    COMPANY_DOMAIN=${COMPANY_DOMAIN:-@example.com}
    
    # Save configuration
    cat > .env.local << EOF
# Auto-generated configuration
# Created: $(date)

SERVICE_NAME=${SERVICE_NAME}
STACK_SUFFIX=${STACK_SUFFIX}
ENVIRONMENT=${ENVIRONMENT}
CUSTOM_DOMAIN=${CUSTOM_DOMAIN}
API_STAGE=prod

AWS_REGION=${AWS_REGION}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
AWS_PROFILE=default

ADMIN_EMAIL=${ADMIN_EMAIL}
COMPANY_DOMAIN=${COMPANY_DOMAIN}

ENABLE_NEWS_SEARCH=false
ENABLE_FILE_UPLOAD=true
MAX_FILE_SIZE_MB=10
SESSION_TIMEOUT_MINUTES=30
EOF
    
    echo ""
    echo "✅ Configuration saved to .env.local"
fi

# Load configuration
source .env.local

echo ""
echo "========================================="
echo "   📋 CONFIGURATION SUMMARY"
echo "========================================="
echo "Service Name: ${SERVICE_NAME}"
echo "Stack Suffix: ${STACK_SUFFIX}"
echo "Environment: ${ENVIRONMENT}"
echo "Domain: ${CUSTOM_DOMAIN}"
echo "AWS Region: ${AWS_REGION}"
echo "Admin Email: ${ADMIN_EMAIL}"
echo ""

# Ask for deployment
read -p "Do you want to deploy the infrastructure now? (y/n): " DEPLOY_NOW

if [ "${DEPLOY_NOW}" = "y" ] || [ "${DEPLOY_NOW}" = "Y" ]; then
    echo ""
    echo "🚀 Starting infrastructure deployment..."
    echo ""
    
    # Generate deployment scripts
    ./scripts/generate-deployment.sh
    
    # Deploy infrastructure
    ./scripts/deploy-infrastructure.sh
    
    echo ""
    echo "========================================="
    echo "   ✅ SETUP COMPLETE!"
    echo "========================================="
    echo ""
    echo "Your service is ready at:"
    echo "  https://${CUSTOM_DOMAIN}"
    echo ""
    echo "Next steps:"
    echo "  1. Update DNS records for ${CUSTOM_DOMAIN}"
    echo "  2. Configure SSL certificate in AWS Certificate Manager"
    echo "  3. Deploy your code: ./deploy.sh"
    echo ""
else
    echo ""
    echo "========================================="
    echo "   📌 SETUP SAVED"
    echo "========================================="
    echo ""
    echo "Configuration saved. To deploy later, run:"
    echo "  ./scripts/deploy-infrastructure.sh"
    echo ""
fi