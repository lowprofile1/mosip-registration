#!/bin/bash

# Setup ECR repositories for MOSIP Registration Processor

set -e

echo "🚀 Setting up ECR repositories for MOSIP Registration Processor"
echo "=============================================================="

AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REGISTRY="921436147132.dkr.ecr.us-east-1.amazonaws.com"

# List of services that need ECR repositories
SERVICES=(
    "registration-processor-registration-transaction-service"
    "registration-processor-stage-group-1"
    "registration-processor-stage-group-2"
    "registration-processor-stage-group-3"
    "registration-processor-stage-group-4"
    "registration-processor-stage-group-5"
    "registration-processor-stage-group-6"
    "registration-processor-stage-group-7"
    "registration-processor-abis"
    "registration-processor-reprocessor"
    "registration-processor-dmz-packet-server"
    "registration-processor-registration-status-service"
    "registration-processor-notification-service"
    "registration-processor-landing-zone"
    "registration-processor-workflow-manager-service"
    "registration-processor-common-camel-bridge"
)

echo "📋 Creating ECR repositories for ${#SERVICES[@]} services..."

for service in "${SERVICES[@]}"; do
    echo "Creating repository: mosip-$service"
    
    # Create repository if it doesn't exist
    aws ecr create-repository \
        --repository-name "mosip-$service" \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true \
        --image-tag-mutability MUTABLE \
        --encryption-configuration encryptionType=AES256 \
        --lifecycle-policy-text '{
            "rules": [
                {
                    "rulePriority": 1,
                    "description": "Keep last 10 images",
                    "selection": {
                        "tagStatus": "any",
                        "countType": "imageCountMoreThan",
                        "countNumber": 10
                    },
                    "action": {
                        "type": "expire"
                    }
                }
            ]
        }' \
        2>/dev/null || echo "Repository mosip-$service already exists"
done

echo ""
echo "✅ ECR repositories created successfully!"
echo ""
echo "📊 Repository Summary:"
echo "====================="

for service in "${SERVICES[@]}"; do
    echo "  - mosip-$service"
done

echo ""
echo "🔧 Next Steps:"
echo "1. Run the GitHub Actions workflow 'Build and Push to ECR'"
echo "2. Verify images are pushed to ECR"
echo "3. Deploy to Kubernetes using 'Deploy to Kubernetes' workflow"
echo ""
echo "🌐 ECR Registry: $ECR_REGISTRY"
echo "📍 Region: $AWS_REGION"

