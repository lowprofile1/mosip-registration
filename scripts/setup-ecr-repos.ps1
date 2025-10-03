# Setup ECR repositories for MOSIP Registration Processor (PowerShell)

Write-Host "🚀 Setting up ECR repositories for MOSIP Registration Processor" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green

$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
$ECR_REGISTRY = "921436147132.dkr.ecr.us-east-1.amazonaws.com"

# List of services that need ECR repositories
$SERVICES = @(
    "registration-processor-registration-transaction-service",
    "registration-processor-stage-group-1",
    "registration-processor-stage-group-2",
    "registration-processor-stage-group-3",
    "registration-processor-stage-group-4",
    "registration-processor-stage-group-5",
    "registration-processor-stage-group-6",
    "registration-processor-stage-group-7",
    "registration-processor-abis",
    "registration-processor-reprocessor",
    "registration-processor-dmz-packet-server",
    "registration-processor-registration-status-service",
    "registration-processor-notification-service",
    "registration-processor-landing-zone",
    "registration-processor-workflow-manager-service",
    "registration-processor-common-camel-bridge"
)

Write-Host "📋 Creating ECR repositories for $($SERVICES.Count) services..." -ForegroundColor Cyan

foreach ($service in $SERVICES) {
    Write-Host "Creating repository: mosip-$service" -ForegroundColor Yellow
    
    # Create repository if it doesn't exist
    $result = aws ecr create-repository --repository-name "mosip-$service" --region $AWS_REGION --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE --encryption-configuration encryptionType=AES256 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Created mosip-$service" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  Repository mosip-$service already exists" -ForegroundColor Blue
    }
}

Write-Host ""
Write-Host "✅ ECR repositories created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Repository Summary:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

foreach ($service in $SERVICES) {
    Write-Host "  - mosip-$service"
}

Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run the GitHub Actions workflow 'Build and Push to ECR'"
Write-Host "2. Verify images are pushed to ECR"
Write-Host "3. Deploy to Kubernetes using 'Deploy to Kubernetes' workflow"
Write-Host ""
Write-Host "🌐 ECR Registry: $ECR_REGISTRY" -ForegroundColor Magenta
Write-Host "📍 Region: $AWS_REGION" -ForegroundColor Magenta