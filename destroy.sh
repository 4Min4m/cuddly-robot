#!/bin/bash

echo "🧹 Cleaning up Axual Demo..."

echo "🗑️ Removing WordPress..."
helm uninstall wordpress || true

echo "🗑️ Removing MySQL Cluster..."
helm uninstall my-mysql-innodbcluster -n mysql-operator || true

echo "🗑️ Removing MySQL Operator..."
helm uninstall mysql-operator -n mysql-operator || true

echo "🗑️ Removing AWS Load Balancer Controller..."
helm uninstall aws-load-balancer-controller -n kube-system || true

echo "🗑️ Removing EBS CSI Driver..."
kubectl delete -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master" || true

echo "🗑️ Removing Kubernetes resources..."
kubectl delete namespace mysql-operator || true

echo "🗑️ Destroying Terraform infrastructure..."
terraform destroy -auto-approve

echo "✅ Cleanup complete!"