#!/bin/bash

# Script to get IP addresses of deployed poker calculator services
# Usage: ./get-poker-ips.sh

set -e

echo "🔍 Getting IP addresses for Poker Calculator services..."
echo ""

# Check if namespace exists
if ! kubectl get namespace poker-calculator &>/dev/null; then
    echo "❌ Namespace 'poker-calculator' not found"
    echo "   Make sure the deployment has been completed"
    exit 1
fi

echo "=== Services ==="
kubectl get services -n poker-calculator
echo ""

echo "=== Frontend LoadBalancer IP ==="
FRONTEND_IP=$(kubectl get service poker-calculator-frontend -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "Pending..." ]; then
    echo "✅ Frontend URL: http://$FRONTEND_IP"
else
    echo "⏳ Frontend LoadBalancer IP is still being assigned..."
    echo "   Run this script again in a few moments"
fi
echo ""

echo "=== Backend LoadBalancer IP ==="
BACKEND_IP=$(kubectl get service poker-calculator-backend-lb -n poker-calculator -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
if [ -n "$BACKEND_IP" ] && [ "$BACKEND_IP" != "Pending..." ]; then
    echo "✅ Backend URL: http://$BACKEND_IP:8080"
    echo ""
    echo "=== Backend API Endpoints ==="
    echo "  Evaluate Hand:"
    echo "    POST http://$BACKEND_IP:8080/poker/evaluate-hand"
    echo "  Compare Hands:"
    echo "    POST http://$BACKEND_IP:8080/poker/compare-hands"
    echo "  Calculate Probability:"
    echo "    POST http://$BACKEND_IP:8080/poker/calculate-probability"
else
    echo "⏳ Backend LoadBalancer IP is still being assigned..."
    echo "   Run this script again in a few moments"
fi
echo ""

echo "=== Pod Status ==="
kubectl get pods -n poker-calculator
echo ""

echo "=== Quick Test Commands ==="
if [ -n "$BACKEND_IP" ] && [ "$BACKEND_IP" != "Pending..." ]; then
    echo ""
    echo "Test backend API:"
    echo "  curl -X POST http://$BACKEND_IP:8080/poker/evaluate-hand \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"hole_cards\": [\"HA\", \"SA\"], \"community_cards\": [\"DA\", \"CA\", \"HK\", \"HQ\", \"HJ\"]}'"
    echo ""
    echo "Or use the test script:"
    echo "  ./test-poker-api.sh http://$BACKEND_IP:8080"
fi

if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "Pending..." ]; then
    echo ""
    echo "Open frontend in browser:"
    echo "  open http://$FRONTEND_IP"
    echo "  # or visit: http://$FRONTEND_IP"
fi
