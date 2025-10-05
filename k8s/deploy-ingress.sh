#!/bin/bash

# Deploy Registration Processor Ingress Manifests
# This script deploys all ingress configurations for the registration processor services

echo "🚀 Deploying Registration Processor Ingress Manifests..."

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

# Create namespace if it doesn't exist
echo "📦 Ensuring namespace exists..."
kubectl create namespace mosip-registration --dry-run=client -o yaml | kubectl apply -f -

# Deploy main combined ingress
echo "🌐 Deploying main combined ingress..."
kubectl apply -f registration-processor-ingress.yaml

# Deploy individual service ingresses
echo "🔧 Deploying individual service ingresses..."

echo "  - Workflow Manager Service Ingress"
kubectl apply -f registration-processor-workflow-manager-ingress.yaml

echo "  - Stage Group 1 Service Ingress"
kubectl apply -f registration-processor-stage-group-1-ingress.yaml

echo "  - Registration Status Service Ingress"
kubectl apply -f registration-processor-registration-status-ingress.yaml

echo "  - Notification Service Ingress"
kubectl apply -f registration-processor-notification-ingress.yaml

echo "  - Landing Zone Service Ingress"
kubectl apply -f registration-processor-landing-zone-ingress.yaml

# Wait for ingress to be ready
echo "⏳ Waiting for ingress to be ready..."
kubectl wait --for=condition=ready ingress --all -n mosip-registration --timeout=60s || echo "⚠️  Some ingresses may not be ready yet"

# Display ingress status
echo "📊 Ingress Status:"
kubectl get ingress -n mosip-registration

echo ""
echo "✅ Ingress deployment completed!"
echo ""
echo "🌐 Access URLs (update your /etc/hosts or DNS):"
echo "  - Main: http://registration.mosip.local"
echo "  - Workflow Manager: http://workflow-manager.registration.mosip.local"
echo "  - Stage Group 1: http://stage-group-1.registration.mosip.local"
echo "  - Registration Status: http://registration-status.registration.mosip.local"
echo "  - Notification: http://notification.registration.mosip.local"
echo "  - Landing Zone: http://landing-zone.registration.mosip.local"
echo ""
echo "📝 Note: Make sure nginx ingress controller is installed and running"
echo "📝 Note: Update your DNS or /etc/hosts file to point these domains to your ingress controller IP"
