# Axual Demo Assessment - Cloud Infrastructure

A production-grade Kubernetes infrastructure demonstrating stateful and stateless application deployment on AWS EKS.

## Overview

Complete cloud-native setup featuring:
- **AWS EKS Cluster** provisioned with Terraform
- **Stateful Application**: MySQL with persistent volumes
- **Stateless Application**: WordPress with external database
- **GitLab CI/CD** pipeline for automated deployments
- **Low-latency optimized** network architecture

## Technical Architecture

### Infrastructure
- Multi-AZ EKS cluster with managed node groups
- Private subnets for application pods, public for load balancers
- EBS CSI Driver for stateful workload persistence
- AWS Load Balancer Controller for ingress management

### Applications
- **MySQL**: Highly available InnoDB cluster with automated backups
- **WordPress**: Decoupled architecture using external MySQL database
- **Public Access**: Secure internet exposure via Application Load Balancer

## Design Decisions

### Platform Selection
- **AWS EKS over Azure AKS**: Better familiarity and account accessibility while maintaining identical cloud-native patterns
- **Terraform for IaC**: Declarative infrastructure management with state tracking
- **Helm for Applications**: Standardized Kubernetes application packaging

### Cost & Performance Optimization
- **t3.medium burstable instances**: Balanced performance and cost efficiency
- **Managed node groups**: Reduced operational overhead
- **Multi-AZ deployment**: High availability without excessive resource allocation

### Security & Operations
- **Private node groups**: Isolated compute resources
- **Minimal IAM roles**: Principle of least privilege
- **Network segmentation**: Separate subnets for different workload types
- **GitLab CI/CD**: Automated testing and deployment validation

## Operational Excellence

### Monitoring Strategy
- **Prometheus Stack**: Cluster-level metrics collection with Grafana dashboards
- **Application Metrics**: WordPress and MySQL performance monitoring
- **AWS CloudWatch**: Infrastructure-level monitoring and alerting
- **Health Checks**: Built-in Kubernetes liveness and readiness probes

### Log Management & Retention
- **EFK Stack**: Fluentd/Fluent-bit for log collection, Elasticsearch for storage, Kibana for visualization
- **Retention Policy**: 
  - Application logs: 30 days
  - Audit logs: 90 days  
  - Security logs: 1 year
- **CloudWatch Logs**: Alternative for simplified AWS-native logging

### Cluster Reliability & Maintenance
- **Managed Node Groups**: Automated node updates and patching
- **Resource Quotas**: CPU/Memory limits to prevent resource exhaustion
- **Horizontal Pod Autoscaling**: Automatic scaling based on application load
- **Regular Backups**: Velero for persistent volume and Kubernetes resource backups
- **Blue-Green Deployments**: Zero-downtime application updates

### Authentication & RBAC
- **IAM Integration**: AWS IAM roles for service accounts (IRSA)
- **Kubernetes RBAC**: 
  - ClusterRoles for team-based access control
  - ServiceAccounts for application permissions
  - Network Policies for micro-segmentation
- **OpenID Connect**: JWT token authentication with OIDC provider

### Network Design & Security
- **VPC Architecture**: 
  - Public subnets for internet-facing load balancers
  - Private subnets for worker nodes and application pods
  - NAT Gateway for outbound internet access from private subnets
- **Security Enforcement**:
  - Security Groups: Layer 3/4 network segmentation
  - Network Policies: Kubernetes network micro-segmentation
  - TLS Encryption: End-to-end SSL/TLS for all external traffic
  - Web Application Firewall: AWS WAF for HTTP/HTTPS protection

## Technology Stack

- **Infrastructure**: Terraform, AWS EKS, VPC networking
- **Applications**: MySQL Operator, WordPress Helm charts
- **Operations**: GitLab CI/CD, Kubernetes, Helm
- **Storage**: EBS volumes with gp2 storage class

---