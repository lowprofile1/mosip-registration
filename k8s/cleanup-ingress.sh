#!/bin/bash

# Cleanup Registration Processor Ingress Manifests
# This script removes all ingress configurations for the registration processor services

echo "🧹 Cleaning up Registration Processor Ingress Manifests..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

# Remove all ingress resources
echo "🗑️  Removing ingress resources..."

echo "  - Main combined ingress"
kubectl delete -f registration-processor-ingress.yaml --ignore-not-found=true

echo "  - Individual service ingresses"
kubectl delete -f registration-processor-workflow-manager-ingress.yaml --ignore-not-found=true
kubectl delete -f registration-processor-stage-group-1-ingress.yaml --ignore-not-found=true
kubectl delete -f registration-processor-registration-status-ingress.yaml --ignore-not-found=true
kubectl delete -f registration-processor-notification-ingress.yaml --ignore-not-found=true
kubectl delete -f registration-processor-landing-zone-ingress.yaml --ignore-not-found=true

# Display remaining ingress resources
echo "📊 Remaining ingress resources:"
kubectl get ingress -n mosip-registration

echo ""
echo "✅ Ingress cleanup completed!"
echo "📝 Note: Services are still running, only ingress routing has been removed"
