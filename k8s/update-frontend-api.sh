#!/bin/bash

# Script to update frontend API URL with backend LoadBalancer IP
# Usage: ./update-frontend-api.sh

set -e

echo "🔍 Getting backend LoadBalancer IP..."

BACKEND_IP=$(kubectl get service temperature-converter-backend-lb -n temperature-converter -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$BACKEND_IP" ]; then
    echo "❌ Backend LoadBalancer IP not found. Waiting for IP assignment..."
    echo "⏳ This may take a few minutes..."
    
    while [ -z "$BACKEND_IP" ]; do
        sleep 10
        BACKEND_IP=$(kubectl get service temperature-converter-backend-lb -n temperature-converter -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -n "$BACKEND_IP" ]; then
            break
        fi
        echo "   Still waiting for IP..."
    done
fi

echo "✅ Backend IP: $BACKEND_IP"
echo "🔄 Updating frontend deployment with API URL..."

kubectl set env deployment/temperature-converter-frontend \
  NEXT_PUBLIC_API_URL=http://$BACKEND_IP:8080 \
  -n temperature-converter

echo "✅ Frontend API URL updated!"
echo ""
echo "⚠️  Note: Since NEXT_PUBLIC_* variables are embedded at build time,"
echo "   you may need to rebuild the frontend image with the correct API URL."
echo ""
echo "   To rebuild:"
echo "   1. cd ../my-calc"
echo "   2. docker build -t gcr.io/PROJECT_ID/temperature-converter-frontend:latest \\"
echo "        --build-arg NEXT_PUBLIC_API_URL=http://$BACKEND_IP:8080 ."
echo "   3. docker push gcr.io/PROJECT_ID/temperature-converter-frontend:latest"
echo "   4. kubectl rollout restart deployment/temperature-converter-frontend -n temperature-converter"

