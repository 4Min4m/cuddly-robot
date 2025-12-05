#!/bin/bash

set -e

echo "🧹 Cleaning up Azure Demo..."

# Configuration
CLUSTER_NAME="axual-demo-cluster"
RESOURCE_GROUP="${CLUSTER_NAME}-rg"

echo "🔧 Getting cluster credentials..."
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing 2>/dev/null || true

echo "🗑️ Removing Nginx application..."
helm uninstall myapp -n myapp --wait || true
kubectl delete namespace myapp --force --grace-period=0 || true

echo "🗑️ Removing MySQL..."
helm uninstall mysql -n mysql --wait || true
kubectl delete namespace mysql --force --grace-period=0 || true

echo "🗑️ Removing StorageClass..."
kubectl delete storageclass azure-disk-premium || true

echo "⏳ Waiting for LoadBalancers to be fully deleted..."
sleep 60

echo "🗑️ Checking for remaining Kubernetes resources..."
kubectl get svc -A || true
kubectl get pvc -A || true

echo "🗑️ Destroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve
cd ..

echo "✅ Cleanup complete!"
echo ""
echo "💡 To verify all resources are deleted:"
echo "az group list --query \"[?name=='${RESOURCE_GROUP}'].name\" -o tsv"