#!/bin/bash

# Deployment script for Poker Calculator on GKE
# Usage: ./deploy-poker.sh <PROJECT_ID> <REGION> <ZONE>

set -e

PROJECT_ID=${1:-"your-project-id"}
REGION=${2:-"us-central1"}
ZONE=${3:-"us-central1-a"}
CLUSTER_NAME="poker-calculator-cluster"

echo "🚀 Starting deployment of Poker Calculator to GKE..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Zone: $ZONE"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

# Set project
echo "📋 Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable APIs
echo "🔌 Enabling required APIs..."
gcloud services enable container.googleapis.com --quiet
gcloud services enable containerregistry.googleapis.com --quiet

# Build and push backend image
echo "🏗️  Building and pushing backend image..."
cd ../backend
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/poker-calculator-backend:latest .
gcloud auth configure-docker --quiet
docker push gcr.io/$PROJECT_ID/poker-calculator-backend:latest
cd ../k8s

# Build and push frontend image (initial build with service name, will be updated after backend LB is ready)
echo "🏗️  Building and pushing frontend image (initial build)..."
cd ../poker_calculator_flutter
# Initial build with service name - will be updated with LoadBalancer IP after backend is ready
docker build --platform linux/amd64 \
  --build-arg API_URL=http://poker-calculator-backend:8080 \
  -t gcr.io/$PROJECT_ID/poker-calculator-frontend:latest .
docker push gcr.io/$PROJECT_ID/poker-calculator-frontend:latest
cd ../k8s

# Update deployment files with project ID
echo "📝 Updating deployment files..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" poker-backend-deployment.yaml
    sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" poker-frontend-deployment.yaml
else
    sed -i "s/PROJECT_ID/$PROJECT_ID/g" poker-backend-deployment.yaml
    sed -i "s/PROJECT_ID/$PROJECT_ID/g" poker-frontend-deployment.yaml
fi

# Check if cluster exists
if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID &> /dev/null; then
    echo "✅ Cluster already exists, getting credentials..."
    gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID
else
    echo "🏗️  Creating GKE cluster..."
    gcloud container clusters create $CLUSTER_NAME \
      --project=$PROJECT_ID \
      --zone=$ZONE \
      --num-nodes=2 \
      --machine-type=e2-medium \
      --enable-autorepair \
      --enable-autoupgrade \
      --enable-autoscaling \
      --min-nodes=1 \
      --max-nodes=3
fi

# Deploy to Kubernetes
echo "🚀 Deploying to Kubernetes..."
kubectl apply -f poker-namespace.yaml
kubectl apply -f poker-backend-deployment.yaml -n poker-calculator
kubectl apply -f poker-backend-service.yaml -n poker-calculator
kubectl apply -f poker-backend-service-lb.yaml -n poker-calculator

# Create ConfigMap for frontend (will be updated with backend IP)
kubectl apply -f poker-frontend-configmap.yaml -n poker-calculator

kubectl apply -f poker-frontend-deployment.yaml -n poker-calculator
kubectl apply -f poker-frontend-service.yaml -n poker-calculator

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/poker-calculator-backend -n poker-calculator || true
kubectl wait --for=condition=available --timeout=300s deployment/poker-calculator-frontend -n poker-calculator || true

# Get service IPs
echo "📊 Getting service information..."
echo ""
echo "=== Services ==="
kubectl get services -n poker-calculator

echo ""
echo "=== Deployments ==="
kubectl get deployments -n poker-calculator

echo ""
echo "=== Pods ==="
kubectl get pods -n poker-calculator

echo ""
echo "⏳ Waiting for backend LoadBalancer to be assigned..."
sleep 10

# Get backend LoadBalancer IP and update frontend
BACKEND_IP=$(kubectl get service poker-calculator-backend-lb -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$BACKEND_IP" ]; then
    echo "✅ Backend LoadBalancer IP: $BACKEND_IP"
    echo "🔄 Updating frontend ConfigMap with backend URL..."
    
    BACKEND_URL="http://$BACKEND_IP:8080"
    
    # Update ConfigMap with backend URL
    kubectl create configmap poker-frontend-config \
      --from-literal=config.js="window.POKER_API_URL = '$BACKEND_URL';" \
      -n poker-calculator --dry-run=client -o yaml | kubectl apply -f -
    
    echo "🔄 Restarting frontend deployment to pick up new config..."
    kubectl rollout restart deployment/poker-calculator-frontend -n poker-calculator
    kubectl rollout status deployment/poker-calculator-frontend -n poker-calculator --timeout=300s || true
    
    echo "✅ Frontend configured to use backend at: $BACKEND_URL"
else
    echo "⚠️  Backend LoadBalancer IP not ready yet."
    echo "   Frontend is using internal service name for now."
    echo "   Run './update-frontend-api-poker.sh $PROJECT_ID' once the backend IP is available"
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "=== Service Information ==="
kubectl get services -n poker-calculator
echo ""
echo "To get the frontend LoadBalancer IP, run:"
echo "  kubectl get service poker-calculator-frontend -n poker-calculator"
echo ""
echo "To get the backend LoadBalancer IP, run:"
echo "  kubectl get service poker-calculator-backend-lb -n poker-calculator"
echo ""
echo "If frontend needs to be updated with backend IP, run:"
echo "  ./update-frontend-api-poker.sh $PROJECT_ID"
echo ""
echo "To test the API manually, use the backend LoadBalancer IP:"
echo "  curl -X POST http://<BACKEND_IP>:8080/poker/evaluate-hand \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"hole_cards\": [\"HA\", \"SA\"], \"community_cards\": [\"DA\", \"CA\", \"HK\", \"HQ\", \"HJ\"]}'"
