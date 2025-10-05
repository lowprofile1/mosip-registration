# Registration Processor Ingress Configuration

This directory contains Kubernetes ingress manifests for the MOSIP Registration Processor services.

## Files Overview

### Main Ingress Files

- **`registration-processor-ingress.yaml`** - Combined ingress with path-based routing
- **`registration-processor-ingress-tls.yaml`** - TLS-enabled version with SSL certificates

### Individual Service Ingress Files

- **`registration-processor-workflow-manager-ingress.yaml`** - Workflow Manager Service
- **`registration-processor-stage-group-1-ingress.yaml`** - Stage Group 1 Service
- **`registration-processor-registration-status-ingress.yaml`** - Registration Status Service
- **`registration-processor-notification-ingress.yaml`** - Notification Service
- **`registration-processor-landing-zone-ingress.yaml`** - Landing Zone Service

### Deployment Script

- **`deploy-ingress.sh`** - Automated deployment script

## Prerequisites

1. **Nginx Ingress Controller** - Must be installed in your cluster
2. **Kubernetes Cluster** - Running and accessible
3. **kubectl** - Configured to access your cluster

## Installation

### Option 1: Using the Deployment Script (Recommended)

```bash
chmod +x deploy-ingress.sh
./deploy-ingress.sh
```

### Option 2: Manual Deployment

```bash
# Apply all ingress manifests
kubectl apply -f registration-processor-ingress.yaml
kubectl apply -f registration-processor-workflow-manager-ingress.yaml
kubectl apply -f registration-processor-stage-group-1-ingress.yaml
kubectl apply -f registration-processor-registration-status-ingress.yaml
kubectl apply -f registration-processor-notification-ingress.yaml
kubectl apply -f registration-processor-landing-zone-ingress.yaml
```

## Access URLs

### Combined Ingress (Path-based routing)

- **Main Entry Point**: `http://registration.mosip.local`
- **Workflow Manager**: `http://registration.mosip.local/registrationprocessor/v1/workflow`
- **Stage Group 1**: `http://registration.mosip.local/registrationprocessor/v1/stagegroup1`
- **Registration Status**: `http://registration.mosip.local/registrationprocessor/v1/registrationstatus`
- **Notification**: `http://registration.mosip.local/registrationprocessor/v1/notification`
- **Landing Zone**: `http://registration.mosip.local/registrationprocessor/v1/landingzone`

### Individual Service Ingress (Subdomain-based routing)

- **Workflow Manager**: `http://workflow-manager.registration.mosip.local`
- **Stage Group 1**: `http://stage-group-1.registration.mosip.local`
- **Registration Status**: `http://registration-status.registration.mosip.local`
- **Notification**: `http://notification.registration.mosip.local`
- **Landing Zone**: `http://landing-zone.registration.mosip.local`

## DNS Configuration

### For Local Development

Add these entries to your `/etc/hosts` file:

```
<INGRESS_CONTROLLER_IP> registration.mosip.local
<INGRESS_CONTROLLER_IP> workflow-manager.registration.mosip.local
<INGRESS_CONTROLLER_IP> stage-group-1.registration.mosip.local
<INGRESS_CONTROLLER_IP> registration-status.registration.mosip.local
<INGRESS_CONTROLLER_IP> notification.registration.mosip.local
<INGRESS_CONTROLLER_IP> landing-zone.registration.mosip.local
```

### For Production

Configure your DNS provider to point these domains to your ingress controller's external IP.

## TLS Configuration

The `registration-processor-ingress-tls.yaml` file includes TLS configuration with:

- **Host**: `registration.mosip.example.com` (update as needed)
- **Certificate**: Managed by cert-manager
- **Issuer**: `letsencrypt-prod` (update as needed)

To use TLS:

1. Install cert-manager in your cluster
2. Create a ClusterIssuer for Let's Encrypt
3. Update the hostname in the TLS ingress file
4. Apply the TLS ingress manifest

## Ingress Annotations

All ingress manifests include the following nginx annotations:

- **CORS**: Enabled for cross-origin requests
- **Proxy Settings**: 10MB body size, 300s timeouts
- **SSL Redirect**: Disabled for HTTP, enabled for HTTPS
- **Rewrite Target**: Path rewriting for proper routing

## Monitoring

Check ingress status:

```bash
kubectl get ingress -n mosip-registration
kubectl describe ingress -n mosip-registration
```

Check nginx ingress controller logs:

```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Troubleshooting

### Common Issues

1. **404 Errors**: Check if services are running and accessible
2. **502 Errors**: Check if pods are ready and healthy
3. **DNS Resolution**: Verify DNS configuration or /etc/hosts entries
4. **TLS Issues**: Check certificate status and cert-manager logs

### Debug Commands

```bash
# Check ingress status
kubectl get ingress -n mosip-registration -o wide

# Check ingress events
kubectl describe ingress -n mosip-registration

# Check nginx configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf

# Test connectivity
curl -H "Host: registration.mosip.local" http://<INGRESS_IP>/registrationprocessor/v1/health
```

## Customization

### Updating Hostnames

Edit the `spec.rules[].host` field in each ingress manifest to match your domain.

### Adding Authentication

Add nginx auth annotations:

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

### Rate Limiting

Add rate limiting annotations:

```yaml
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "100"
  nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```
