#!/bin/bash

set -e

echo "🚀 Starting Axual Demo Deployment..."

echo "📦 Step 1: Deploying EKS Cluster with Terraform..."
terraform init
terraform apply -auto-approve

echo "🔧 Step 2: Configuring kubectl..."
aws eks update-kubeconfig --region eu-west-1 --name axual-demo-cluster

echo "💾 Step 3: Installing EBS CSI Driver..."
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

echo "🌐 Step 4: Installing AWS Load Balancer Controller..."
helm repo add aws-load-balancer-controller https://aws.github.io/load-balancer-controller
helm install aws-load-balancer-controller aws-load-balancer-controller/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=axual-demo-cluster

echo "⏳ Step 5: Waiting for cluster components..."
sleep 60

echo "🗄️  Step 6: Deploying MySQL..."
helm repo add mysql-operator https://mysql.github.io/mysql-operator/
helm install mysql-operator mysql-operator/mysql-operator \
  --namespace mysql-operator --create-namespace

kubectl wait --for=condition=ready pod -n mysql-operator -l app.kubernetes.io/name=mysql-operator --timeout=300s

helm install my-mysql-innodbcluster mysql-operator/mysql-innodbcluster \
  -n mysql-operator \
  --set credentials.root.password="DemoPassword123!" \
  --set database="wordpress" \
  --set tls.useSelfSigned=true \
  --set instances=1

echo "👤 Step 7: Creating database user..."
sleep 30

kubectl run mysql-init --image=mysql:8.0 -it --rm --restart=Never -- \
  mysql -h my-mysql-innodbcluster.mysql-operator.svc.cluster.local -u root -pDemoPassword123! -e "
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wordpress'@'%' IDENTIFIED BY 'wordpress123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;"

echo "🌍 Step 8: Deploying WordPress..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install wordpress bitnami/wordpress \
  --namespace default \
  --set wordpressUsername=admin \
  --set wordpressPassword="AdminPass123!" \
  --set wordpressEmail=demo@axual.com \
  --set mariadb.enabled=false \
  --set externalDatabase.host="my-mysql-innodbcluster.mysql-operator.svc.cluster.local" \
  --set externalDatabase.user=wordpress \
  --set externalDatabase.password=wordpress123 \
  --set externalDatabase.database=wordpress \
  --set externalDatabase.port=3306 \
  --set persistence.enabled=true \
  --set persistence.storageClass=gp2 \
  --set persistence.size=5Gi \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.ingressClassName=alb \
  --set ingress.annotations."alb\.ingress\.kubernetes\.io/scheme"=internet-facing \
  --set ingress.annotations."alb\.ingress\.kubernetes\.io/target-type"=ip \
  --set ingress.hostname=wordpress.demo.axual.com \
  --timeout 10m

echo "⏳ Step 9: Waiting for WordPress to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=wordpress --timeout=600s

echo "🎉 Step 10: Deployment Complete!"
echo ""
echo "📊 Cluster Status:"
kubectl get pods -A

echo ""
echo "🌐 WordPress Access:"
echo "Run: kubectl port-forward svc/wordpress 8080:80"
echo "Then open: http://localhost:8080"
echo "Admin: http://localhost:8080/wp-admin"
echo "Username: admin"
echo "Password: AdminPass123!"

echo ""
echo "🗑️  To clean up: ./destroy.sh"