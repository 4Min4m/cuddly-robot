#!/bin/bash

set -e

echo "🚀 Starting Azure Demo Deployment..."

# Configuration
CLUSTER_NAME="axual-demo-cluster"
RESOURCE_GROUP="${CLUSTER_NAME}-rg"
AZURE_REGION="eastus"

echo "📦 Step 1: Deploying AKS Cluster with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "🔧 Step 2: Configuring kubectl..."
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing

echo "⏳ Step 3: Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "💾 Step 4: Creating Azure Premium SSD StorageClass..."
kubectl apply -f helm/azure-disk-sc.yaml
kubectl get storageclass

echo "🗄️  Step 5: Deploying MySQL..."
kubectl create namespace mysql --dry-run=client -o yaml | kubectl apply -f -
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install mysql bitnami/mysql \
  --namespace mysql \
  --values helm/mysql-values.yaml \
  --set auth.rootPassword="DemoPassword123!" \
  --set auth.database="test" \
  --set auth.username="test" \
  --set auth.password="test123" \
  --wait --timeout=10m

echo "⏳ Step 6: Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mysql -n mysql --timeout=600s

echo "🌍 Step 7: Deploying Nginx Application..."
kubectl create namespace myapp --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install myapp helm \
  --namespace myapp \
  --values helm/myapp-values.yaml \
  --set service.type=LoadBalancer

echo "⏳ Step 8: Waiting for Nginx to be ready..."
kubectl wait --for=condition=ready pod -l app=my-app -n myapp --timeout=300s

echo "⏳ Step 9: Waiting for LoadBalancer IP assignment..."
sleep 30

echo "🎉 Step 10: Deployment Complete!"
echo ""
echo "📊 Cluster Status:"
kubectl get pods -A

echo ""
echo "🌐 Application Access:"
EXTERNAL_IP=$(kubectl get svc -n myapp -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
if [ -n "$EXTERNAL_IP" ]; then
  echo "Nginx URL: http://${EXTERNAL_IP}"
else
  echo "LoadBalancer IP still provisioning. Run this to check:"
  echo "kubectl get svc -n myapp"
fi

echo ""
echo "🗄️  MySQL Access:"
echo "kubectl exec -it mysql-0 -n mysql -- mysql -u root -p"
echo "Password: DemoPassword123!"

echo ""
echo "🗑️  To clean up: ./destroy.sh"