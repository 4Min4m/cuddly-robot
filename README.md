```markdown
# Axual Demo Scenario Assessment

A complete cloud infrastructure demo showcasing Kubernetes cluster deployment with stateful and stateless applications, designed for low-latency environments.

## 🚀 Overview

This project demonstrates a production-ready infrastructure setup featuring:
- **EKS Cluster** on AWS with Terraform
- **Stateful Application**: MySQL with persistent storage
- **Stateless Application**: WordPress with external database
- **CI/CD Pipeline**: GitLab CI for automated deployments
- **Monitoring Ready**: Prepared for Prometheus/Grafana integration

## 📁 Project Structure

```
axual-demo/
├── .gitlab-ci.yml          # CI/CD pipeline
├── main.tf                 # Terraform infrastructure
├── variables.tf            # Terraform variables
├── deploy.sh              # Manual deployment script
├── destroy.sh             # Cleanup script
└── README.md              # This file
```

## 🛠️ Quick Start

### Prerequisites
- AWS account with credentials
- GitLab account with CI/CD configured
- kubectl, helm, and terraform installed (for manual deployment)

### Automated Deployment (Recommended)
1. Set AWS credentials in GitLab CI/CD variables:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. Push to main branch - pipeline will automatically:
   - Create EKS cluster with Terraform
   - Deploy EBS CSI Driver and ALB Controller
   - Install MySQL Operator and create database
   - Deploy WordPress with external MySQL
   - Run smoke tests

### Manual Deployment
```bash
# Apply infrastructure
terraform init
terraform apply -auto-approve

# Run complete deployment
./deploy.sh
```

## 🌐 Access Applications

After deployment:
- **WordPress**: http://wordpress.your-domain.demo.axual.com
- **Admin**: http://wordpress.your-domain.demo.axual.com/wp-admin
  - Username: `admin`
  - Password: `AdminPass123!`

## 🔧 Key Features

### Infrastructure
- Multi-AZ EKS cluster for high availability
- Private subnets for low-latency pod communication
- EBS CSI Driver for stateful application persistence
- AWS Load Balancer Controller for ingress

### Applications
- **MySQL**: Highly available InnoDB cluster with persistence
- **WordPress**: Stateless application with external database
- **Public Access**: Internet-facing ALB with proper security groups

### Operations
- GitLab CI/CD with 4-stage pipeline
- Terraform plan/apply with artifact passing
- Health checks and retry logic
- Smoke tests for deployment validation

## 🗑️ Cleanup

```bash
# Automated cleanup
./destroy.sh

# Or via GitLab pipeline (manual trigger)
```

## 💡 Design Decisions

- **AWS over Azure**: Used AWS EKS due to account accessibility, maintaining same architectural patterns
- **Cost Optimization**: t3.medium burstable instances, managed node groups
- **Security**: Private node groups, minimal IAM roles, network isolation
- **Stateful Handling**: EBS CSI Driver with gp2 storage class for MySQL persistence

## 📞 Support

For questions about this implementation:
- Infrastructure: Terraform files in root directory
- Applications: Helm charts deployed via CI/CD
- Pipeline: `.gitlab-ci.yml` for automation logic

---
*Demonstrating modern DevOps practices for cloud-native application deployment.*