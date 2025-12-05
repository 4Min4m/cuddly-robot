# Demo Assessment - Cloud Infrastructure (Azure)

A production-grade Kubernetes infrastructure demonstrating stateful and stateless application deployment on Azure AKS.

## Overview

Complete cloud-native setup featuring:
- **Azure AKS Cluster** provisioned with Terraform
- **Stateful Application**: MySQL with persistent volumes (Premium SSD)
- **Stateless Application**: Nginx web server
- **GitLab CI/CD** pipeline for automated deployments
- **Low-latency optimized** network architecture

## Technical Architecture

### Infrastructure
- AKS cluster (v1.30) with managed node pools
- Virtual Network with dedicated subnet for AKS
- Azure Disk CSI Driver for stateful workload persistence (built-in)
- Azure Load Balancer for public internet access (built-in)
- System-assigned managed identity for secure Azure API access

### Applications
- **MySQL 8.0**: Bitnami Helm chart with persistent storage (10Gi Premium SSD)
- **Nginx**: Lightweight web server accessible via Azure LoadBalancer
- **Public Access**: Internet-facing Azure Load Balancer

## Project Structure

```
.
├── README.md
├── terraform/
│   ├── main.tf                    # AKS cluster, VNet, managed identity
│   └── variables.tf               # Cluster configuration
├── helm/
│   ├── Chart.yaml                 # Nginx application chart
│   ├── values.yaml                # Default values
│   ├── myapp-values.yaml          # Custom overrides
│   ├── mysql-values.yaml          # MySQL configuration (Azure)
│   ├── azure-disk-sc.yaml        # Premium SSD StorageClass
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── _helpers.tpl
└── .gitlab-ci.yml                # CI/CD pipeline (Azure)
```

## Design Decisions

### Platform Selection
- **Azure AKS**: Fully managed Kubernetes with seamless Azure integration
- **Terraform for IaC**: Declarative infrastructure with state management and reproducibility
- **Helm for Applications**: Standardized Kubernetes packaging with version control
- **GitLab CI/CD**: Automated deployment pipeline with manual approval gates

### Cost & Performance Optimization
- **Standard_D2s_v3 instances**: 2 vCPU, 8GB RAM - balanced performance/cost
- **2-node cluster**: Sufficient for demo workloads with auto-scaling capability (min: 1, max: 3)
- **Single region deployment**: eastus for low latency
- **Premium SSD storage**: High-performance persistent disks with better IOPS
- **Managed node pools**: Reduced operational overhead with automatic updates

### Security & Operations
- **System-assigned managed identity**: No credential management required
- **Virtual Network integration**: Isolated network environment for AKS
- **Azure CNI networking**: Direct pod IP addressing for better performance
- **Network policies**: Built-in Azure Network Policy support

## Deployment Pipeline

### GitLab CI/CD Stages

1. **Validate**: Terraform plan and validation
2. **Infrastructure**: AKS cluster provisioning (~10-15 min)
3. **Deploy**: 
   - Prerequisites (StorageClass)
   - MySQL deployment with persistent volumes
   - Nginx application deployment
4. **Test**: Smoke tests for resource validation
5. **Destroy**: Cleanup jobs for safe teardown

### Pipeline Features
- Manual approval gates for infrastructure changes
- Artifact caching for Terraform plans
- Parallel job execution where possible
- Comprehensive error handling with `|| true` fallbacks
- Automated kubeconfig management via Azure CLI

## Operational Excellence

### Monitoring Strategy
**Recommended Stack (not implemented in demo):**
- **Azure Monitor for Containers**: Native AKS monitoring
  - Node and pod resource utilization
  - Container logs and metrics
  - Performance insights and alerts
- **Prometheus + Grafana**: Application-level metrics
  - MySQL query performance and connection pools
  - Nginx request rates and response times
- **Azure Application Insights**: Application performance monitoring

**Implementation approach:**
```bash
# Enable Azure Monitor
az aks enable-addons -a monitoring \
  -n ${CLUSTER_NAME} \
  -g ${RESOURCE_GROUP}

# Install Prometheus stack
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

### Log Management & Retention
**Recommended Stack:**
- **Azure Monitor Logs**: Centralized log collection
  - Container logs automatically collected
  - Query with KQL (Kusto Query Language)
  - Integration with Azure Sentinel for security
- **Alternative**: Fluent-bit + Elasticsearch + Kibana

**Retention Policy:**
- Application logs: 30 days
- Audit logs: 90 days
- Security logs: 1 year

**Implementation:**
```bash
# Logs are automatically collected when Azure Monitor is enabled
# Query in Azure Portal under Monitor > Logs
```

### Cluster Reliability & Maintenance

**High Availability:**
- Availability Zones support (can be enabled for production)
- Managed node pools with automatic security patching
- Azure Disk replication within region

**Backup Strategy:**
- **Velero with Azure plugin**: Kubernetes resource and volume backups
  - Daily automated backups to Azure Blob Storage
  - 7-day retention for development
  - 30-day retention for production
- **MySQL**: Automated daily backups via Bitnami chart

**Scaling:**
- Horizontal Pod Autoscaler (HPA) based on CPU/memory
- Cluster Autoscaler for node pool expansion (enabled by default)
- Resource requests/limits defined in all deployments

**Maintenance Windows:**
- Node pool updates: Automatic during configured maintenance window
- Application deployments: Blue-green strategy for zero downtime
- Database maintenance: Automated backup before schema changes

**Implementation:**
```bash
# Install Velero for backups
velero install \
  --provider azure \
  --plugins velero/velero-plugin-for-microsoft-azure:v1.9.0 \
  --bucket aks-backup-container \
  --backup-location-config resourceGroup=${RESOURCE_GROUP},storageAccount=velerostorage
```

### Authentication & RBAC

**Cluster Access:**
- **Azure AD Integration**: Primary authentication mechanism
  - Azure AD users/groups mapped to Kubernetes RBAC
  - MFA enforcement through Azure AD
- **Managed Identity**: AKS uses system-assigned identity
  - No service principal credentials to manage
  - Automatic token rotation

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

**Best Practices:**
- Namespace-based isolation (myapp, mysql, kube-system)
- ServiceAccounts for all application pods
- NetworkPolicies for pod-to-pod communication restrictions
- Azure Policy for Kubernetes for compliance

### Network Design & Security

**VNet Architecture:**
```
VNet (10.0.0.0/16)
└── AKS Subnet (10.0.1.0/24)
    ├── AKS Nodes
    ├── Application Pods
    └── MySQL StatefulSets
```

**Traffic Flow:**
1. **Inbound**: Internet → Azure Load Balancer → Service → Pod
2. **Outbound**: Pod → Azure Default Route → Internet
3. **Inter-pod**: Direct communication within VNet (Azure CNI)

**Security Layers:**

1. **Network Level:**
   - Network Security Groups (NSGs): Stateful firewall rules
   - Azure Firewall: Optional centralized outbound filtering
   - VNet service endpoints: Secure access to Azure services

2. **Kubernetes Level:**
   - Azure Network Policies: Micro-segmentation between namespaces
   - PodSecurityStandards: Enforce security best practices
   - Azure Application Gateway Ingress Controller: WAF integration

3. **Application Level:**
   - TLS encryption for all external traffic
   - Azure Key Vault for secrets management
   - Container image scanning with Azure Container Registry

**Implemented Security:**
- Private node pools (nodes not directly exposed)
- LoadBalancer service type for controlled public exposure
- System-assigned managed identity with least privilege

## Technology Stack

**Infrastructure:**
- Terraform 1.13.5
- Azure AKS 1.30
- VNet with dedicated subnet
- Azure Disk CSI Driver (built-in)
- Azure Load Balancer (built-in)

**Applications:**
- MySQL 8.0 (Bitnami Helm chart)
- Nginx 1.25-alpine
- Helm 3.17

**CI/CD:**
- GitLab CI/CD
- Alpine Linux base image
- Azure CLI, kubectl, terraform, helm

**Storage:**
- Premium SSD (Premium_LRS)
- 10Gi persistent storage for MySQL
- WaitForFirstConsumer volume binding

## Quick Start

### Prerequisites
- Azure subscription with appropriate permissions
- GitLab account with CI/CD runners
- Azure service principal credentials configured as GitLab CI/CD variables:
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`

### Creating Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac --name "gitlab-ci-demo" --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"

# Output will provide:
# - appId (AZURE_CLIENT_ID)
# - password (AZURE_CLIENT_SECRET)
# - tenant (AZURE_TENANT_ID)
```

### Deployment Steps

1. **Clone repository and configure variables** in `.gitlab-ci.yml`:
   ```yaml
   variables:
     CLUSTER_NAME: "demo-cluster"
     AZURE_REGION: "eastus"
   ```

2. **Run pipeline stages** (GitLab UI):
   - Trigger `validate_terraform` (manual)
   - Trigger `deploy_infrastructure` (manual, ~15 min)
   - Automatic: `deploy_prerequisites`, `deploy_mysql`, `deploy_app`
   - Automatic: `smoke_tests`

3. **Access applications**:
   ```bash
   # Get LoadBalancer IP
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

**⚠️ Important:** Always run cleanup in order (K8s resources → Terraform) to avoid orphaned Azure resources.

## Cost Estimation

**Monthly costs (eastus):**
- AKS Cluster: Free (pay only for nodes)
- VMs (2x Standard_D2s_v3): ~$140
- Load Balancer: ~$20
- Premium SSD: ~$20
- **Total: ~$180/month**

**Cost optimization tips:**
- Stop cluster when not in use: `az aks stop --name ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP}`
- Start when needed: `az aks start --name ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP}`
- Use Spot VMs for non-production workloads
- Enable cluster autoscaling to scale to minimum

## Troubleshooting

### Common Issues

**Azure Disk not attaching:**
```bash
# Verify managed identity permissions
az role assignment list --assignee $(az aks show -n ${CLUSTER_NAME} -g ${RESOURCE_GROUP} --query identity.principalId -o tsv)

# Check pod events
kubectl describe pod <pod-name> -n mysql
```

**LoadBalancer stuck in pending:**
```bash
# Check service events
kubectl describe svc myapp-my-app -n myapp

# Verify NSG rules
az network nsg list -g ${RESOURCE_GROUP}
```

**Terraform destroy fails:**
```bash
# Delete LoadBalancer services first via kubectl
kubectl delete svc -n myapp --all
kubectl delete svc -n mysql --all

# Wait for Azure to clean up LoadBalancers
sleep 60

# Then retry destroy
terraform destroy -auto-approve
```

**Authentication issues:**
```bash
# Re-authenticate
az login

# Get kubeconfig again
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing
```

## Azure vs AWS Comparison

| Feature | AWS EKS | Azure AKS |
|---------|---------|-----------|
| **Control Plane Cost** | $73/month | Free |
| **Managed Identity** | IRSA (complex setup) | Built-in (simple) |
| **Networking** | VPC with public/private subnets | VNet with single subnet |
| **Storage** | EBS CSI (manual install) | Azure Disk CSI (built-in) |
| **Load Balancer** | ALB Controller (manual) | Built-in integration |
| **Node Pricing** | t3.medium: ~$30/node | D2s_v3: ~$70/node |
| **Setup Time** | 20-25 minutes | 10-15 minutes |
| **Complexity** | Higher (more components) | Lower (more managed) |

## Future Enhancements

- [ ] Enable Azure Monitor for Containers
- [ ] Add Azure Application Gateway Ingress Controller
- [ ] Configure Velero for backup/restore
- [ ] Implement GitOps with ArgoCD or Flux
- [ ] Add Horizontal Pod Autoscaling
- [ ] Configure Ingress with TLS certificates from Azure Key Vault
- [ ] Implement Azure Network Policies for namespace isolation
- [ ] Enable Azure AD integration for RBAC
- [ ] Add Azure Policy for Kubernetes compliance
- [ ] Enable Availability Zones for production workloads

## Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Monitor for Containers](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview)