#!/bin/bash

# Script to update frontend API URL after backend LoadBalancer is created
# Usage: ./update-frontend-api-poker.sh

set -e

PROJECT_ID=${1:-$(gcloud config get-value project 2>/dev/null)}

if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID not provided and gcloud project not set"
    echo "Usage: ./update-frontend-api-poker.sh <PROJECT_ID>"
    exit 1
fi

echo "🔍 Getting backend LoadBalancer IP..."
BACKEND_IP=$(kubectl get service poker-calculator-backend-lb -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$BACKEND_IP" ]; then
    echo "⚠️  Backend LoadBalancer IP not available yet. Waiting..."
    echo "Waiting for LoadBalancer to be assigned..."
    for i in {1..30}; do
        BACKEND_IP=$(kubectl get service poker-calculator-backend-lb -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$BACKEND_IP" ]; then
            break
        fi
        echo "  Attempt $i/30..."
        sleep 5
    done
fi

if [ -z "$BACKEND_IP" ]; then
    echo "❌ Could not get backend LoadBalancer IP"
    echo "Please check: kubectl get service poker-calculator-backend-lb -n poker-calculator"
    exit 1
fi

BACKEND_URL="http://$BACKEND_IP:8080"
echo "✅ Backend URL: $BACKEND_URL"

echo "🔄 Updating frontend ConfigMap with backend URL..."
kubectl create configmap poker-frontend-config \
  --from-literal=config.js="window.POKER_API_URL = '$BACKEND_URL';" \
  -n poker-calculator --dry-run=client -o yaml | kubectl apply -f -

echo "🔄 Restarting frontend deployment to pick up new config..."
kubectl rollout restart deployment/poker-calculator-frontend -n poker-calculator

echo "⏳ Waiting for rollout to complete..."
kubectl rollout status deployment/poker-calculator-frontend -n poker-calculator --timeout=300s

echo ""
echo "✅ Frontend updated and restarted!"
echo ""
echo "Frontend is now configured to use backend at: $BACKEND_URL"
echo ""
echo "Get frontend LoadBalancer IP:"
echo "  kubectl get service poker-calculator-frontend -n poker-calculator"
