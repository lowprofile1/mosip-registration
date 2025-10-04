# MOSIP Registration Processor - CI/CD Setup

This document describes the CI/CD pipeline for the MOSIP Registration Processor, designed to build, push, and deploy Docker images to AWS EKS.

## 🏗️ Architecture Overview

The CI/CD pipeline consists of three main workflows:

### 1. **Build and Push to ECR** (`build-and-push-ecr.yml`)

- **Purpose**: Build Maven artifacts and Docker images, push to ECR
- **Triggers**: Push to master/develop/main, PRs, manual dispatch
- **Services**: 16 registration processor services
- **Output**: Docker images in ECR ready for deployment

### 2. **Deploy to Kubernetes** (`deploy-to-kubernetes.yml`)

- **Purpose**: Deploy services to EKS cluster
- **Triggers**: After successful ECR build, manual dispatch
- **Target**: `mosip-ida-dev` EKS cluster
- **Namespace**: `mosip-registration`

### 3. **Build Only** (`build-only.yml`)

- **Purpose**: Test builds without pushing to ECR
- **Triggers**: Manual dispatch only
- **Use Case**: Development and testing

## 📦 Services Included

The pipeline builds and deploys 16 registration processor services:

### **Core Services**

- `registration-processor-workflow-manager-service` - Main orchestrator
- `registration-processor-registration-status-service` - Status tracking
- `registration-processor-notification-service` - Notifications

### **Stage Groups (Processing Pipeline)**

- `registration-processor-stage-group-1` - Packet receiver
- `registration-processor-stage-group-2` - Securezone notification, Quality classifier
- `registration-processor-stage-group-3` - ABIS handler, Bio dedupe, Manual adjudication
- `registration-processor-stage-group-4` - Biometric authentication, Demo dedupe
- `registration-processor-stage-group-5` - CMD validator, Operator validator, Supervisor validator
- `registration-processor-stage-group-6` - Packet uploader, Packet classifier, Verification
- `registration-processor-stage-group-7` - UIN generator, Biometric extraction, Finalization

### **Supporting Services**

- `registration-processor-abis` - ABIS integration
- `registration-processor-reprocessor` - Reprocessing
- `registration-processor-dmz-packet-server` - DMZ packet server
- `registration-processor-landing-zone` - Landing zone
- `registration-processor-common-camel-bridge` - Camel bridge

## 🔧 Configuration

### **Environment Variables**

```yaml
# Build Configuration
MAVEN_OPTS: -Dmaven.repo.local=.m2/repository
AWS_REGION: us-east-1
ECR_REGISTRY: 921436147132.dkr.ecr.us-east-1.amazonaws.com
EKS_CLUSTER_NAME: mosip-ida-dev

# Service Configuration
SPRING_PROFILES_ACTIVE: dev
SPRING_CLOUD_CONFIG_LABEL: main
SPRING_CLOUD_CONFIG_URI: http://config-server:8888
ARTIFACTORY_URL: http://artifactory:8081
IAM_ADAPTER_URL: http://artifactory:8081/kernel-auth-adapter.jar
IS_GLOWROOT: absent
```

### **Required GitHub Secrets**

```yaml
AWS_ACCESS_KEY_ID: # AWS access key for ECR and EKS
AWS_SECRET_ACCESS_KEY: # AWS secret key
DB_PASSWORD: # Database password for registration processor
```

### **Docker Build Arguments**

```dockerfile
# Standard build arguments for all services:
SOURCE=github.com/mosip/registration
COMMIT_HASH=${{ github.sha }}
COMMIT_ID=${{ github.sha }}
BUILD_TIME=${{ github.event.head_commit.timestamp }}
spring_config_label=main
active_profile=dev
spring_config_url=http://config-server:8888
is_glowroot=absent
artifactory_url=http://artifactory:8081
iam_adapter_url=http://artifactory:8081/kernel-auth-adapter.jar
regproc_jars=artifactory/libs-release-local/regproc/
```

## 🚀 Usage

### **Automatic Deployment**

1. **Push to main branch** - Triggers build and deployment
2. **Create Pull Request** - Triggers build only (no deployment)
3. **Manual trigger** - Use GitHub Actions UI

### **Manual Deployment**

```bash
# Deploy all services
kubectl apply -f k8s/ -n mosip-registration

# Deploy specific service
kubectl apply -f k8s/registration-processor-workflow-manager-service.yaml -n mosip-registration

# Check status
kubectl get pods -n mosip-registration
kubectl get services -n mosip-registration
```

### **Local Testing**

```bash
# Build only (no push)
gh workflow run build-only.yml

# Build specific service
gh workflow run build-only.yml -f service_name=registration-processor-workflow-manager-service
```

## 📊 Resource Requirements

### **Per Service (Kubernetes)**

```yaml
# Workflow Manager (Main Service)
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

# Stage Groups
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

# Supporting Services
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### **Total Cluster Requirements**

- **CPU**: ~8-12 cores (with 2 replicas per service)
- **Memory**: ~16-24GB (with 2 replicas per service)
- **Storage**: Persistent volumes for logs and packet storage

## 🔍 Health Checks

### **Health Endpoints**

```yaml
# Workflow Manager
/registrationprocessor/v1/workflow/actuator/health

# Stage Groups
/registrationprocessor/v1/packetreceiver/actuator/health

# Status Service
/registrationprocessor/v1/registrationstatus/actuator/health

# Notification Service
/registrationprocessor/v1/notification/actuator/health
```

### **Probe Configuration**

```yaml
livenessProbe:
  initialDelaySeconds: 120
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 6

readinessProbe:
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

## 📁 Directory Structure

```
mosip-registration/
├── .github/workflows/
│   ├── build-and-push-ecr.yml      # Main CI/CD pipeline
│   ├── deploy-to-kubernetes.yml    # Kubernetes deployment
│   └── build-only.yml              # Local testing
├── k8s/
│   ├── namespace.yaml              # Namespace and secrets
│   ├── registration-processor-workflow-manager-service.yaml
│   ├── registration-processor-stage-group-1.yaml
│   ├── registration-processor-registration-status-service.yaml
│   ├── registration-processor-notification-service.yaml
│   ├── deploy.sh                   # Bash deployment script
│   └── deploy.ps1                  # PowerShell deployment script
├── registration-processor/          # Maven project
└── CICD_README.md                  # This documentation
```

## 🔧 Troubleshooting

### **Common Issues**

#### **Build Failures**

```bash
# Check Maven build logs
kubectl logs -f deployment/registration-processor-workflow-manager-service -n mosip-registration

# Check Docker build logs in GitHub Actions
# Look for Maven compilation errors or missing dependencies
```

#### **Deployment Failures**

```bash
# Check pod status
kubectl get pods -n mosip-registration

# Check pod logs
kubectl logs -f deployment/registration-processor-workflow-manager-service -n mosip-registration

# Check events
kubectl get events -n mosip-registration --sort-by='.lastTimestamp'
```

#### **Service Connectivity**

```bash
# Check service endpoints
kubectl get services -n mosip-registration

# Port forward for testing
kubectl port-forward svc/registration-processor-workflow-manager-service 8081:8081 -n mosip-registration

# Test health endpoint
curl http://localhost:8081/registrationprocessor/v1/workflow/actuator/health
```

### **Debugging Commands**

```bash
# Check all resources
kubectl get all -n mosip-registration

# Check persistent volumes
kubectl get pv,pvc -n mosip-registration

# Check secrets
kubectl get secrets -n mosip-registration

# Check config maps
kubectl get configmaps -n mosip-registration
```

## 🔄 Integration with Existing Infrastructure

### **Shared Resources**

- **EKS Cluster**: `mosip-ida-dev` (shared with authentication services)
- **RDS Database**: `mosip-ida-dev-db` (shared database)
- **ECR Registry**: `921436147132.dkr.ecr.us-east-1.amazonaws.com`
- **Monitoring**: Prometheus + Grafana (shared monitoring stack)

### **Namespace Separation**

- **Authentication**: `mosip-ida` namespace
- **Registration**: `mosip-registration` namespace
- **Monitoring**: `monitoring` namespace
- **Logging**: `logging` namespace

## 📈 Monitoring and Logging

### **Metrics Collection**

- **Prometheus**: Collects metrics from all services
- **Grafana**: Dashboards for registration processor metrics
- **Health Checks**: Kubernetes liveness and readiness probes

### **Log Management**

- **Application Logs**: Stored in `/home/logs` volume
- **Packet Storage**: `/home/ftp1/ARCHIVE_PACKET_LOCATION`
- **Landing Zone**: `/home/ftp1/LANDING_ZONE`

### **Accessing Logs**

```bash
# Application logs
kubectl logs -f deployment/registration-processor-workflow-manager-service -n mosip-registration

# All pods logs
kubectl logs -f -l app.kubernetes.io/component=mosip -n mosip-registration
```

## 🎯 Next Steps

1. **Set up GitHub Secrets** for AWS credentials and database password
2. **Run the build workflow** to create ECR repositories and build images
3. **Deploy to Kubernetes** using the deployment workflow
4. **Monitor services** using Prometheus and Grafana
5. **Scale services** based on load requirements

---

**Status**: ✅ **Ready for Deployment**
**Last Updated**: October 2025
**Version**: 1.2.1.2

