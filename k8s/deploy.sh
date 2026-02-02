#!/bin/bash

# Deployment script for Temperature Converter on GKE
# Usage: ./deploy.sh <PROJECT_ID> <REGION> <ZONE>

set -e

PROJECT_ID=${1:-"your-project-id"}
REGION=${2:-"us-central1"}
ZONE=${3:-"us-central1-a"}
CLUSTER_NAME="temperature-converter-cluster"

echo "🚀 Starting deployment to GKE..."
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
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/temperature-converter-backend:latest .
gcloud auth configure-docker --quiet
docker push gcr.io/$PROJECT_ID/temperature-converter-backend:latest
cd ../k8s

# Build and push frontend image
echo "🏗️  Building and pushing frontend image..."
cd ../temperature_converter_flutter
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/temperature-converter-frontend:latest \
  --build-arg API_URL=http://temperature-converter-backend:8080 .
docker push gcr.io/$PROJECT_ID/temperature-converter-frontend:latest
cd ../k8s

# Update deployment files with project ID
echo "📝 Updating deployment files..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" backend-deployment.yaml
    sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" frontend-deployment.yaml
else
    sed -i "s/PROJECT_ID/$PROJECT_ID/g" backend-deployment.yaml
    sed -i "s/PROJECT_ID/$PROJECT_ID/g" frontend-deployment.yaml
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
kubectl apply -f namespace.yaml
kubectl apply -f backend-deployment.yaml -n temperature-converter
kubectl apply -f backend-service.yaml -n temperature-converter
kubectl apply -f backend-service-lb.yaml -n temperature-converter
kubectl apply -f frontend-deployment.yaml -n temperature-converter
kubectl apply -f frontend-service.yaml -n temperature-converter

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/temperature-converter-backend -n temperature-converter
kubectl wait --for=condition=available --timeout=300s deployment/temperature-converter-frontend -n temperature-converter

# Get service IPs
echo "📊 Getting service information..."
echo ""
echo "=== Services ==="
kubectl get services -n temperature-converter

echo ""
echo "=== Deployments ==="
kubectl get deployments -n temperature-converter

echo ""
echo "=== Pods ==="
kubectl get pods -n temperature-converter

echo ""
echo "✅ Deployment complete!"
echo ""
echo "To get the frontend LoadBalancer IP, run:"
echo "  kubectl get service temperature-converter-frontend -n temperature-converter"
echo ""
echo "To get the backend LoadBalancer IP, run:"
echo "  kubectl get service temperature-converter-backend-lb -n temperature-converter"
echo ""
echo "Once you have the backend IP, update the frontend deployment:"
echo "  kubectl set env deployment/temperature-converter-frontend NEXT_PUBLIC_API_URL=http://<BACKEND_IP>:8080 -n temperature-converter"

