#!/bin/bash

# Script to verify poker calculator deployment
# Usage: ./verify-deployment.sh

echo "🔍 Verifying Poker Calculator Deployment..."
echo ""

echo "=== Deployments ==="
kubectl get deployments -n poker-calculator
echo ""

echo "=== Pods Status ==="
kubectl get pods -n poker-calculator
echo ""

echo "=== Services ==="
kubectl get services -n poker-calculator
echo ""

echo "=== Checking Pod Readiness ==="
READY_PODS=$(kubectl get pods -n poker-calculator --field-selector=status.phase=Running --no-headers | wc -l | tr -d ' ')
TOTAL_PODS=$(kubectl get pods -n poker-calculator --no-headers | wc -l | tr -d ' ')

echo "Running Pods: $READY_PODS / $TOTAL_PODS"
echo ""

if [ "$READY_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    echo "✅ All pods are running!"
else
    echo "⏳ Some pods are still starting. Wait a moment and check again."
    echo ""
    echo "To watch pod status:"
    echo "  kubectl get pods -n poker-calculator -w"
fi

echo ""
echo "=== LoadBalancer IPs ==="
FRONTEND_IP=$(kubectl get service poker-calculator-frontend -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
BACKEND_IP=$(kubectl get service poker-calculator-backend-lb -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$FRONTEND_IP" ]; then
    echo "✅ Frontend IP: http://$FRONTEND_IP"
else
    echo "⏳ Frontend LoadBalancer IP pending..."
fi

if [ -n "$BACKEND_IP" ]; then
    echo "✅ Backend IP: http://$BACKEND_IP:8080"
else
    echo "⏳ Backend LoadBalancer IP pending..."
fi

echo ""
echo "=== Next Steps ==="
echo "1. Wait for pods to be in 'Running' state"
echo "2. Wait for LoadBalancer IPs to be assigned (can take 1-2 minutes)"
echo "3. Test the frontend: open http://<FRONTEND_IP> in browser"
echo "4. Test the backend: use ./test-poker-api.sh http://<BACKEND_IP>:8080"
