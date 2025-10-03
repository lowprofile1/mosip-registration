#!/bin/bash

# MOSIP Registration Processor - Kubernetes Deployment Script

set -e

echo "🚀 Deploying MOSIP Registration Processor to Kubernetes"
echo "======================================================"

# Check prerequisites
echo "📋 Checking prerequisites..."
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Configure AWS credentials and EKS
echo "🔧 Configuring AWS and EKS..."
AWS_REGION=${AWS_REGION:-us-east-1}
EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME:-mosip-ida-dev}

aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Verify cluster connection
echo "🔍 Verifying cluster connection..."
kubectl get nodes
kubectl get namespaces

# Create namespace and secrets
echo "📦 Creating namespace and secrets..."
kubectl apply -f namespace.yaml

# Create database secret if not exists
kubectl create secret generic mosip-registration-secrets \
  --from-literal=DB_PASSWORD="${DB_PASSWORD:-postgres}" \
  --from-literal=DB_USERNAME="${DB_USERNAME:-postgres}" \
  --namespace=mosip-registration \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy services
echo "🚀 Deploying registration services..."
kubectl apply -f registration-processor-workflow-manager-service.yaml
kubectl apply -f registration-processor-stage-group-1.yaml
kubectl apply -f registration-processor-registration-status-service.yaml
kubectl apply -f registration-processor-notification-service.yaml

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/component=mosip -n mosip-registration

# Display status
echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo ""
echo "📊 Service Status:"
kubectl get deployments -n mosip-registration
echo ""
echo "🔍 Pod Status:"
kubectl get pods -n mosip-registration
echo ""
echo "🌐 Services:"
kubectl get services -n mosip-registration
echo ""
echo "📋 Access Information:"
echo "  Cluster: $EKS_CLUSTER_NAME"
echo "  Namespace: mosip-registration"
echo "  Region: $AWS_REGION"
echo ""
echo "🔧 Useful Commands:"
echo "  kubectl logs -f deployment/registration-processor-workflow-manager-service -n mosip-registration"
echo "  kubectl port-forward svc/registration-processor-workflow-manager-service 8081:8081 -n mosip-registration"
echo "  kubectl get events -n mosip-registration --sort-by='.lastTimestamp'"
