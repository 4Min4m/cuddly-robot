# Demo Assessment - Cloud Infrastructure

A production-grade Kubernetes infrastructure demonstrating stateful and stateless application deployment on AWS EKS.

## Overview

Complete cloud-native setup featuring:
- **AWS EKS Cluster** provisioned with Terraform
- **Stateful Application**: MySQL with persistent volumes (gp3)
- **Stateless Application**: Nginx web server
- **GitLab CI/CD** pipeline for automated deployments
- **Low-latency optimized** network architecture

## Technical Architecture

### Infrastructure
- Multi-AZ EKS cluster (v1.30) with managed node groups
- Private subnets for application pods, public subnets for load balancers
- EBS CSI Driver for stateful workload persistence
- AWS Load Balancer Controller for public internet access
- NAT Gateway for secure outbound connectivity

### Applications
- **MySQL 8.0**: Bitnami Helm chart with persistent storage (10Gi gp3 volumes)
- **Nginx**: Lightweight web server accessible via AWS LoadBalancer
- **Public Access**: Internet-facing Application Load Balancer

## Project Structure

```
.
├── README.md
├── terraform/
│   ├── main.tf                    # EKS cluster, VPC, IAM roles
│   ├── variables.tf               # Cluster configuration
│   └── policies/
│       └── aws-load-balancer-controller-policy.json
├── helm/
│   ├── Chart.yaml                 # Nginx application chart
│   ├── values.yaml                # Default values
│   ├── myapp-values.yaml          # Custom overrides
│   ├── mysql-values.yaml          # MySQL configuration
│   ├── gp3-sc.yaml               # GP3 StorageClass
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── _helpers.tpl
└── .gitlab-ci.yml                # CI/CD pipeline
```

## Design Decisions

### Platform Selection
- **AWS EKS over Azure AKS**: Maintained identical cloud-native patterns while using accessible infrastructure
- **Terraform for IaC**: Declarative infrastructure with state management and reproducibility
- **Helm for Applications**: Standardized Kubernetes packaging with version control
- **GitLab CI/CD**: Automated deployment pipeline with manual approval gates

### Cost & Performance Optimization
- **t3.medium burstable instances**: 2 vCPU, 4GB RAM - balanced performance/cost
- **2-node cluster**: Sufficient for demo workloads with auto-scaling capability (min: 1, max: 3)
- **Multi-AZ deployment**: High availability across us-east-1a and us-east-1b
- **gp3 EBS volumes**: Latest generation with better price/performance ratio
- **Managed node groups**: Reduced operational overhead

### Security & Operations
- **Private node groups**: Worker nodes isolated in private subnets
- **IRSA (IAM Roles for Service Accounts)**: Least privilege access for EBS CSI and ALB Controller
- **Network segmentation**: Separate public/private subnet routing
- **Security groups**: Restrictive ingress/egress rules

## Deployment Pipeline

### GitLab CI/CD Stages

1. **Validate**: Terraform plan and validation
2. **Infrastructure**: EKS cluster provisioning (~15-20 min)
3. **Deploy**: 
   - Prerequisites (EBS CSI, ALB Controller, StorageClass)
   - MySQL deployment with persistent volumes
   - Nginx application deployment
4. **Test**: Smoke tests for resource validation
5. **Destroy**: Cleanup jobs for safe teardown

### Pipeline Features
- Manual approval gates for infrastructure changes
- Artifact caching for Terraform plans
- Parallel job execution where possible
- Comprehensive error handling with `|| true` fallbacks
- Automated kubeconfig management

## Operational Excellence

### Monitoring Strategy
**Recommended Stack (not implemented in demo):**
- **Prometheus + Grafana**: Cluster and application metrics
  - Node resource utilization (CPU, memory, disk)
  - Pod health and restart counts
  - MySQL query performance and connection pools
  - Nginx request rates and response times
- **AWS CloudWatch**: Infrastructure-level monitoring
  - EKS control plane logs
  - VPC flow logs for network analysis
  - LoadBalancer metrics (request count, latency, error rates)
- **Health Checks**: Kubernetes liveness and readiness probes

**Implementation approach:**
```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

### Log Management & Retention
**Recommended Stack:**
- **Fluent-bit**: Lightweight log shipper running as DaemonSet
- **Elasticsearch**: Centralized log storage with indexing
- **Kibana**: Log visualization and search interface

**Retention Policy:**
- Application logs: 30 days (debug/info level)
- Audit logs: 90 days (compliance requirement)
- Security logs: 1 year (incident investigation)

**Alternative:** AWS CloudWatch Logs with automatic retention policies

**Implementation:**
```bash
helm install fluent-bit fluent/fluent-bit \
  --set backend.type=es \
  --set backend.es.host=elasticsearch
```

### Cluster Reliability & Maintenance

**High Availability:**
- Multi-AZ node distribution for fault tolerance
- Managed node groups with automatic security patching
- EBS volume replication within availability zones

**Backup Strategy:**
- **Velero**: Kubernetes resource and persistent volume backups
  - Daily automated backups
  - 7-day retention for development
  - 30-day retention for production
- **MySQL**: Automated daily backups via Bitnami chart configuration

**Scaling:**
- Horizontal Pod Autoscaler (HPA) based on CPU/memory
- Cluster Autoscaler for node group expansion
- Resource requests/limits defined in all deployments

**Maintenance Windows:**
- Node group updates: Weekly during off-peak hours
- Application deployments: Blue-green strategy for zero downtime
- Database maintenance: Automated backup before schema changes

**Implementation:**
```bash
# Install Velero for backups
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket eks-backup-bucket \
  --backup-location-config region=us-east-1
```

### Authentication & RBAC

**Cluster Access:**
- **AWS IAM**: Primary authentication mechanism
  - IAM users/roles mapped to Kubernetes groups
  - MFA enforcement for production access
- **OIDC Provider**: EKS-integrated identity federation
  - Service accounts use IRSA for AWS API calls
  - No long-lived credentials stored in pods

**RBAC Structure:**
```yaml
# Example RBAC for development team
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer
rules:
- apiGroups: ["apps", ""]
  resources: ["deployments", "pods", "services"]
  verbs: ["get", "list", "watch", "create", "update"]
```

**Implemented Roles:**
- **EBS CSI Driver**: `system:serviceaccount:kube-system:ebs-csi-controller-sa`
- **ALB Controller**: `system:serviceaccount:kube-system:aws-load-balancer-controller`

**Best Practices:**
- Namespace-based isolation (myapp, mysql, kube-system)
- ServiceAccounts for all application pods
- NetworkPolicies for pod-to-pod communication restrictions

### Network Design & Security

**VPC Architecture:**
```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.0.0/24, 10.0.1.0/24)
│   ├── Internet Gateway
│   ├── NAT Gateway
│   └── LoadBalancers (internet-facing)
└── Private Subnets (10.0.10.0/24, 10.0.11.0/24)
    ├── EKS Worker Nodes
    ├── Application Pods
    └── MySQL StatefulSets
```

**Traffic Flow:**
1. **Inbound**: Internet → ALB (public subnet) → NodePort → Pod (private subnet)
2. **Outbound**: Pod → NAT Gateway (public subnet) → Internet Gateway
3. **Inter-pod**: Direct communication within VPC (CNI plugin)

**Security Layers:**

1. **Network Level:**
   - Security Groups: Stateful firewall rules at instance level
   - Network ACLs: Stateless subnet-level filtering
   - VPC Flow Logs: Network traffic audit trail

2. **Kubernetes Level:**
   - NetworkPolicies: Micro-segmentation between namespaces
   - PodSecurityStandards: Enforce security best practices
   - Ingress Controllers: TLS termination and WAF integration

3. **Application Level:**
   - TLS encryption for all external traffic
   - Secrets management via AWS Secrets Manager or Kubernetes Secrets
   - Container image scanning (Trivy, Clair)

**Implemented Security:**
- Private node groups (no direct internet access)
- LoadBalancer service type for controlled public exposure
- IAM least-privilege roles for service accounts

## Technology Stack

**Infrastructure:**
- Terraform 1.13.5
- AWS EKS 1.30
- VPC with multi-AZ subnets
- EBS CSI Driver 2.x
- AWS Load Balancer Controller 2.x

**Applications:**
- MySQL 8.0 (Bitnami Helm chart)
- Nginx 1.25-alpine
- Helm 3.17

**CI/CD:**
- GitLab CI/CD
- Alpine Linux base image
- AWS CLI, kubectl, terraform, helm

**Storage:**
- gp3 EBS volumes (encrypted)
- 10Gi persistent storage for MySQL
- WaitForFirstConsumer volume binding

## Quick Start

### Prerequisites
- AWS account with appropriate IAM permissions
- GitLab account with CI/CD runners
- AWS credentials configured as GitLab CI/CD variables:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

### Deployment Steps

1. **Clone repository and configure variables** in `.gitlab-ci.yml`:
   ```yaml
   variables:
     CLUSTER_NAME: "demo-cluster"
     AWS_REGION: "us-east-1"
   ```

2. **Run pipeline stages** (GitLab UI):
   - Trigger `validate_terraform` (manual)
   - Trigger `deploy_infrastructure` (manual, ~20 min)
   - Automatic: `deploy_prerequisites`, `deploy_mysql`, `deploy_app`
   - Automatic: `smoke_tests`

3. **Access applications**:
   ```bash
   # Get LoadBalancer URL
   kubectl get svc -n myapp
   curl http://<EXTERNAL-IP>
   ```

4. **Verify MySQL**:
   ```bash
   kubectl get pods -n mysql
   kubectl exec -it mysql-0 -n mysql -- mysql -u root -p
   ```

### Cleanup

**Option 1: GitLab Pipeline**
- Trigger `cleanup_k8s_resources` (manual)
- Trigger `destroy_infrastructure` (manual)

**Option 2: Manual Cleanup**
```bash
# Delete Helm releases
helm uninstall myapp -n myapp
helm uninstall mysql -n mysql

# Delete infrastructure
cd terraform
terraform destroy -auto-approve
```

**⚠️ Important:** Always run cleanup in order (K8s resources → Terraform) to avoid orphaned AWS resources.

## Cost Estimation

**Monthly costs (us-east-1):**
- EKS Cluster: $73
- EC2 (2x t3.medium): ~$60
- NAT Gateway: ~$32
- EBS Volumes: ~$5
- LoadBalancers: ~$20
- **Total: ~$190/month**

**Cost optimization tips:**
- Stop cluster when not in use: `eksctl delete cluster --name demo-cluster`
- Use Spot instances for non-production workloads
- Enable cluster autoscaling to scale to zero

## Troubleshooting

### Common Issues

**EBS CSI Driver not working:**
```bash
# Verify IAM role
aws iam get-role --role-name demo-cluster-ebs-csi-driver

# Check pod logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

**LoadBalancer stuck in pending:**
```bash
# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify service
kubectl describe svc myapp-my-app -n myapp
```

**Terraform destroy fails:**
```bash
# Force delete LoadBalancers first
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' | \
  xargs -I {} aws elbv2 delete-load-balancer --load-balancer-arn {}

# Then retry destroy
terraform destroy -auto-approve
```

## Future Enhancements

- [ ] Implement monitoring stack (Prometheus + Grafana)
- [ ] Add centralized logging (EFK stack)
- [ ] Configure Velero for backup/restore
- [ ] Implement GitOps with ArgoCD
- [ ] Add Horizontal Pod Autoscaling
- [ ] Configure Ingress with TLS certificates
- [ ] Implement NetworkPolicies for namespace isolation
- [ ] Add Kubernetes Dashboard for cluster visualization
