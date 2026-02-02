#!/bin/bash

# Script to diagnose and fix deployment issues
# Usage: ./fix-deployment-issues.sh <PROJECT_ID>

set -e

PROJECT_ID=${1:-""}

if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID is required"
    echo "Usage: ./fix-deployment-issues.sh <PROJECT_ID>"
    echo ""
    echo "To find your project ID:"
    echo "  gcloud config get-value project"
    exit 1
fi

echo "🔍 Diagnosing deployment issues..."
echo ""

# Check backend logs
echo "=== Backend Pod Logs ==="
BACKEND_POD=$(kubectl get pods -n poker-calculator -l app=poker-calculator-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$BACKEND_POD" ]; then
    echo "Checking logs for pod: $BACKEND_POD"
    kubectl logs -n poker-calculator $BACKEND_POD --tail=30 || echo "Could not retrieve logs"
else
    echo "No backend pods found"
fi
echo ""

# Check frontend image issue
echo "=== Frontend Image Issue ==="
echo "The frontend deployment likely has PROJECT_ID placeholder instead of actual project ID"
echo "Current image in deployment:"
kubectl get deployment poker-calculator-frontend -n poker-calculator -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Could not retrieve"
echo ""
echo ""

# Fix frontend deployment
echo "🔧 Fixing frontend deployment image..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" poker-frontend-deployment.yaml
else
    sed -i "s/PROJECT_ID/$PROJECT_ID/g" poker-frontend-deployment.yaml
fi

echo "✅ Updated frontend deployment with project ID: $PROJECT_ID"
echo ""

# Apply the fix
echo "🚀 Applying fixed deployment..."
kubectl apply -f poker-frontend-deployment.yaml -n poker-calculator

echo ""
echo "⏳ Waiting for frontend pods to restart..."
sleep 5

echo ""
echo "=== Updated Pod Status ==="
kubectl get pods -n poker-calculator

echo ""
echo "=== Next Steps ==="
echo "1. Check backend logs to see why it's crashing:"
echo "   kubectl logs -n poker-calculator <backend-pod-name>"
echo ""
echo "2. Check backend pod description:"
echo "   kubectl describe pod -n poker-calculator <backend-pod-name>"
echo ""
echo "3. Wait for frontend pods to start (should fix InvalidImageName)"
echo ""
echo "4. Once pods are running, check IPs:"
echo "   ./get-poker-ips.sh"
