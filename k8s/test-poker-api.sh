#!/bin/bash

# Manual testing script for Poker Calculator API
# Usage: ./test-poker-api.sh <BACKEND_URL>
# Example: ./test-poker-api.sh http://localhost:8080
# Example: ./test-poker-api.sh http://<LOADBALANCER_IP>:8080

set -e

BACKEND_URL=${1:-"http://localhost:8080"}

echo "🧪 Testing Poker Calculator API at $BACKEND_URL"
echo ""

# Test 1: Evaluate Hand - Royal Flush
echo "Test 1: Evaluate Hand (Royal Flush)"
echo "-----------------------------------"
curl -X POST "$BACKEND_URL/poker/evaluate-hand" \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "SA"],
    "community_cards": ["DA", "CA", "HK", "HQ", "HJ"]
  }' | jq .
echo ""
echo ""

# Test 2: Evaluate Hand - Three of a Kind
echo "Test 2: Evaluate Hand (Three of a Kind)"
echo "---------------------------------------"
curl -X POST "$BACKEND_URL/poker/evaluate-hand" \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "S7"],
    "community_cards": ["DA", "CA", "H5", "S2", "C9"]
  }' | jq .
echo ""
echo ""

# Test 3: Compare Hands
echo "Test 3: Compare Hands"
echo "--------------------"
curl -X POST "$BACKEND_URL/poker/compare-hands" \
  -H "Content-Type: application/json" \
  -d '{
    "player1_hole_cards": ["HA", "SA"],
    "player1_community_cards": ["DA", "CA", "HK", "HQ", "HJ"],
    "player2_hole_cards": ["HK", "HQ"],
    "player2_community_cards": ["DA", "CA", "HA", "SA", "HJ"]
  }' | jq .
echo ""
echo ""

# Test 4: Calculate Probability (Pre-flop)
echo "Test 4: Calculate Win Probability (Pre-flop, 4 players, 1000 sims)"
echo "------------------------------------------------------------------"
curl -X POST "$BACKEND_URL/poker/calculate-probability" \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "SA"],
    "community_cards": [],
    "num_players": 4,
    "num_simulations": 1000
  }' | jq .
echo ""
echo ""

# Test 5: Calculate Probability (Flop)
echo "Test 5: Calculate Win Probability (Flop, 3 players, 1000 sims)"
echo "-------------------------------------------------------------"
curl -X POST "$BACKEND_URL/poker/calculate-probability" \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "SA"],
    "community_cards": ["DA", "CA", "HK"],
    "num_players": 3,
    "num_simulations": 1000
  }' | jq .
echo ""
echo ""

echo "✅ All tests completed!"
