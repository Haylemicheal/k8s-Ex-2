package poker

import (
	"testing"
)

func TestEvaluateHand(t *testing.T) {
	testCases := []struct {
		name           string
		holeCards      []string
		communityCards []string
		expectedHand   string
		description    string
	}{
		// Royal Flush
		{
			name:           "Royal Flush - Hearts",
			holeCards:      []string{"HT", "HJ"},
			communityCards: []string{"HQ", "HK", "HA", "S2", "C3"},
			expectedHand:   "Royal Flush",
		},
		// Straight Flush
		{
			name:           "Straight Flush",
			holeCards:      []string{"H5", "H6"},
			communityCards: []string{"H7", "H8", "H9", "S2", "C3"},
			expectedHand:   "Straight Flush",
		},
		// Four of a Kind
		{
			name:           "Four of a Kind - Aces",
			holeCards:      []string{"HA", "SA"},
			communityCards: []string{"DA", "CA", "HK", "HQ", "HJ"},
			expectedHand:   "Four of a Kind",
		},
		// Full House
		{
			name:           "Full House - Kings over Aces",
			holeCards:      []string{"HK", "SK"},
			communityCards: []string{"DK", "HA", "SA", "H5", "S2"},
			expectedHand:   "Full House",
		},
		// Flush
		{
			name:           "Flush - Hearts",
			holeCards:      []string{"H2", "H7"},
			communityCards: []string{"H5", "HK", "HQ", "S2", "C3"},
			expectedHand:   "Flush",
		},
		// Straight
		{
			name:           "Straight - 5-6-7-8-9",
			holeCards:      []string{"H5", "S6"},
			communityCards: []string{"H7", "D8", "C9", "S2", "C3"},
			expectedHand:   "Straight",
		},
		// Three of a Kind
		{
			name:           "Three of a Kind - Aces",
			holeCards:      []string{"HA", "S7"},
			communityCards: []string{"DA", "CA", "H5", "S2", "C9"},
			expectedHand:   "Three of a Kind",
		},
		// Two Pair
		{
			name:           "Two Pair - Aces and Kings",
			holeCards:      []string{"HA", "SK"},
			communityCards: []string{"DA", "CK", "H5", "S2", "C9"},
			expectedHand:   "Two Pair",
		},
		// Pair
		{
			name:           "Pair - Aces",
			holeCards:      []string{"HA", "S7"},
			communityCards: []string{"DA", "CK", "HQ", "S2", "C9"},
			expectedHand:   "Pair",
		},
		// High Card
		{
			name:           "High Card - King high",
			holeCards:      []string{"H2", "S7"},
			communityCards: []string{"DK", "CQ", "HJ", "S5", "C9"},
			expectedHand:   "High Card",
		},
		// Wheel Straight (A-2-3-4-5)
		{
			name:           "Wheel Straight",
			holeCards:      []string{"HA", "H2"},
			communityCards: []string{"H3", "H4", "H5", "S7", "C9"},
			expectedHand:   "Straight Flush",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			holeCards, err := ParseCards(tc.holeCards)
			if err != nil {
				t.Fatalf("Failed to parse hole cards: %v", err)
			}

			communityCards, err := ParseCards(tc.communityCards)
			if err != nil {
				t.Fatalf("Failed to parse community cards: %v", err)
			}

			hand := EvaluateBestHand(holeCards, communityCards)

			if hand.Description != tc.expectedHand {
				t.Errorf("Expected %s, got %s", tc.expectedHand, hand.Description)
				t.Logf("Hole cards: %v", tc.holeCards)
				t.Logf("Community cards: %v", tc.communityCards)
				t.Logf("Hand value: %d", hand.Value)
				t.Logf("Best 5 cards: %v", hand.Cards)
			}
		})
	}
}

func TestCompareHands(t *testing.T) {
	testCases := []struct {
		name           string
		player1Hole    []string
		player1Comm    []string
		player2Hole    []string
		player2Comm    []string
		expectedWinner int // 1 for player1, 2 for player2, 0 for tie
	}{
		{
			name:           "Royal Flush beats Straight",
			player1Hole:    []string{"HT", "HJ"},
			player1Comm:    []string{"HQ", "HK", "HA", "S2", "C3"},
			player2Hole:    []string{"H5", "S6"},
			player2Comm:    []string{"H7", "D8", "C9", "S2", "C3"},
			expectedWinner: 1,
		},
		{
			name:           "Full House beats Flush",
			player1Hole:    []string{"HK", "SK"},
			player1Comm:    []string{"DK", "HA", "SA", "H5", "S2"},
			player2Hole:    []string{"H2", "H7"},
			player2Comm:    []string{"H5", "HK", "HQ", "S2", "C3"},
			expectedWinner: 1,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			p1Hole, _ := ParseCards(tc.player1Hole)
			p1Comm, _ := ParseCards(tc.player1Comm)
			p2Hole, _ := ParseCards(tc.player2Hole)
			p2Comm, _ := ParseCards(tc.player2Comm)

			hand1 := EvaluateBestHand(p1Hole, p1Comm)
			hand2 := EvaluateBestHand(p2Hole, p2Comm)

			winner := 0
			if hand1.Value > hand2.Value {
				winner = 1
			} else if hand2.Value > hand1.Value {
				winner = 2
			}

			if winner != tc.expectedWinner {
				t.Errorf("Expected winner %d, got %d", tc.expectedWinner, winner)
				t.Logf("Player 1: %s (value: %d)", hand1.Description, hand1.Value)
				t.Logf("Player 2: %s (value: %d)", hand2.Description, hand2.Value)
			}
		})
	}
}
