#!/bin/bash

# Rebuild and push images with correct platform
# Usage: ./rebuild-images.sh <PROJECT_ID>

set -e

PROJECT_ID=${1:-""}

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Please provide PROJECT_ID"
    echo "Usage: ./rebuild-images.sh YOUR_PROJECT_ID"
    exit 1
fi

echo "🔧 Rebuilding images for linux/amd64 platform..."

# Build and push backend image
echo "🏗️  Building and pushing backend image..."
cd ../backend
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/temperature-converter-backend:latest .
gcloud auth configure-docker --quiet
docker push gcr.io/$PROJECT_ID/temperature-converter-backend:latest
cd ../k8s

# Build and push frontend image
echo "🏗️  Building and pushing frontend image..."
cd ../my-calc
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/temperature-converter-frontend:latest \
  --build-arg NEXT_PUBLIC_API_URL=http://temperature-converter-backend:8080 .
docker push gcr.io/$PROJECT_ID/temperature-converter-frontend:latest
cd ../k8s

echo "✅ Images rebuilt and pushed!"
echo ""
echo "🔄 Restarting deployments..."
kubectl rollout restart deployment/temperature-converter-backend -n temperature-converter
kubectl rollout restart deployment/temperature-converter-frontend -n temperature-converter

echo "⏳ Waiting for deployments to be ready..."
kubectl rollout status deployment/temperature-converter-backend -n temperature-converter --timeout=300s
kubectl rollout status deployment/temperature-converter-frontend -n temperature-converter --timeout=300s

echo ""
echo "✅ Done! Check status with:"
echo "   kubectl get pods -n temperature-converter"


