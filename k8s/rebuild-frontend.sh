#!/bin/bash

# Script to rebuild and redeploy frontend with fixes
# Usage: ./rebuild-frontend.sh <PROJECT_ID> <BACKEND_IP>

set -e

PROJECT_ID=${1:-"pocker-486211"}
BACKEND_IP=${2:-"34.135.82.97"}

if [ -z "$BACKEND_IP" ]; then
    echo "Getting backend IP from service..."
    BACKEND_IP=$(kubectl get service poker-calculator-backend-lb -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -z "$BACKEND_IP" ]; then
        echo "❌ Could not get backend IP. Please provide it as second argument."
        exit 1
    fi
fi

BACKEND_URL="http://$BACKEND_IP:8080"
echo "🔨 Rebuilding frontend with backend URL: $BACKEND_URL"

cd ../poker_calculator_flutter

# Build Flutter web app
echo "Building Flutter web app..."
flutter build web --release --dart-define=API_URL=$BACKEND_URL

# Build Docker image
echo "Building Docker image..."
docker build --platform linux/amd64 \
  --build-arg API_URL=$BACKEND_URL \
  -t gcr.io/$PROJECT_ID/poker-calculator-frontend:latest .

# Push to GCR
echo "Pushing to GCR..."
gcloud auth configure-docker --quiet
docker push gcr.io/$PROJECT_ID/poker-calculator-frontend:latest

cd ../k8s

# Restart deployment
echo "Restarting frontend deployment..."
kubectl rollout restart deployment/poker-calculator-frontend -n poker-calculator

echo "⏳ Waiting for rollout..."
kubectl rollout status deployment/poker-calculator-frontend -n poker-calculator --timeout=300s

echo ""
echo "✅ Frontend rebuilt and redeployed!"
echo "Get frontend IP: kubectl get service poker-calculator-frontend -n poker-calculator"
