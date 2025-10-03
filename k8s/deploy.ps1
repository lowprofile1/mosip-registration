# MOSIP Registration Processor - Kubernetes Deployment Script (PowerShell)

Write-Host "🚀 Deploying MOSIP Registration Processor to Kubernetes" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Cyan
try {
    kubectl version --client | Out-Null
    Write-Host "✅ kubectl found" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl not found. Please install kubectl." -ForegroundColor Red
    exit 1
}

try {
    aws --version | Out-Null
    Write-Host "✅ AWS CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI." -ForegroundColor Red
    exit 1
}

# Configure AWS credentials and EKS
Write-Host "🔧 Configuring AWS and EKS..." -ForegroundColor Cyan
$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
$EKS_CLUSTER_NAME = if ($env:EKS_CLUSTER_NAME) { $env:EKS_CLUSTER_NAME } else { "mosip-ida-dev" }

aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Verify cluster connection
Write-Host "🔍 Verifying cluster connection..." -ForegroundColor Cyan
kubectl get nodes
kubectl get namespaces

# Create namespace and secrets
Write-Host "📦 Creating namespace and secrets..." -ForegroundColor Cyan
kubectl apply -f namespace.yaml

# Create database secret if not exists
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "postgres" }
$DB_USERNAME = if ($env:DB_USERNAME) { $env:DB_USERNAME } else { "postgres" }

kubectl create secret generic mosip-registration-secrets `
  --from-literal=DB_PASSWORD="$DB_PASSWORD" `
  --from-literal=DB_USERNAME="$DB_USERNAME" `
  --namespace=mosip-registration `
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy services
Write-Host "🚀 Deploying registration services..." -ForegroundColor Cyan
kubectl apply -f registration-processor-workflow-manager-service.yaml
kubectl apply -f registration-processor-stage-group-1.yaml
kubectl apply -f registration-processor-registration-status-service.yaml
kubectl apply -f registration-processor-notification-service.yaml

# Wait for deployments
Write-Host "⏳ Waiting for deployments to be ready..." -ForegroundColor Cyan
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/component=mosip -n mosip-registration

# Display status
Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Service Status:" -ForegroundColor Cyan
kubectl get deployments -n mosip-registration
Write-Host ""
Write-Host "🔍 Pod Status:" -ForegroundColor Cyan
kubectl get pods -n mosip-registration
Write-Host ""
Write-Host "🌐 Services:" -ForegroundColor Cyan
kubectl get services -n mosip-registration
Write-Host ""
Write-Host "📋 Access Information:" -ForegroundColor Yellow
Write-Host "  Cluster: $EKS_CLUSTER_NAME"
Write-Host "  Namespace: mosip-registration"
Write-Host "  Region: $AWS_REGION"
Write-Host ""
Write-Host "🔧 Useful Commands:" -ForegroundColor Yellow
Write-Host "  kubectl logs -f deployment/registration-processor-workflow-manager-service -n mosip-registration"
Write-Host "  kubectl port-forward svc/registration-processor-workflow-manager-service 8081:8081 -n mosip-registration"
Write-Host "  kubectl get events -n mosip-registration --sort-by='.lastTimestamp'"
