package poker

import (
	"testing"
)

func TestExcelTestCases(t *testing.T) {
	testCases := []struct {
		name           string
		handType       string
		communityCards []string
		player1Hole    []string
		player2Hole    []string
		expectedResult string // "player1", "player2", or "tie"
	}{
		{
			name:           "Excel Test 1 - High Card",
			handType:       "High Card",
			communityCards: []string{"D6", "S9", "H4", "S3", "C2"},
			player1Hole:    []string{"SK", "CA"},
			player2Hole:    []string{"HA", "SQ"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 2 - High Card",
			handType:       "High Card",
			communityCards: []string{"D6", "S9", "H4", "S3", "C2"},
			player1Hole:    []string{"SK", "CA"},
			player2Hole:    []string{"HA", "CK"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 3 - High Card",
			handType:       "High Card",
			communityCards: []string{"D6", "S9", "H4", "H3", "H2"},
			player1Hole:    []string{"C7", "DQ"},
			player2Hole:    []string{"C8", "DJ"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 4 - One Pair",
			handType:       "One Pair",
			communityCards: []string{"SK", "HT", "C8", "C7", "D2"},
			player1Hole:    []string{"DK", "C5"},
			player2Hole:    []string{"H8", "D5"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 5 - One Pair",
			handType:       "One Pair",
			communityCards: []string{"SK", "HT", "C8", "C7", "D2"},
			player1Hole:    []string{"DK", "C4"},
			player2Hole:    []string{"HK", "D5"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 6 - One Pair",
			handType:       "One Pair",
			communityCards: []string{"HA", "DA", "ST", "C9", "D4"},
			player1Hole:    []string{"D5", "C6"},
			player2Hole:    []string{"H7", "C2"},
			expectedResult: "player2",
		},
		{
			name:           "Excel Test 7 - Two Pairs",
			handType:       "Two Pairs",
			communityCards: []string{"SA", "DQ", "CK", "D6", "H6"},
			player1Hole:    []string{"HA", "C3"},
			player2Hole:    []string{"CQ", "H4"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 8 - Two Pairs",
			handType:       "Two Pairs",
			communityCards: []string{"SA", "DQ", "CK", "D6", "H6"},
			player1Hole:    []string{"HQ", "C3"},
			player2Hole:    []string{"SQ", "H4"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 9 - Two Pairs",
			handType:       "Two Pairs",
			communityCards: []string{"SA", "DQ", "CK", "D6", "H5"},
			player1Hole:    []string{"HQ", "C6"},
			player2Hole:    []string{"CA", "HK"},
			expectedResult: "player2",
		},
		{
			name:           "Excel Test 10 - Three of a Kind",
			handType:       "Three of a Kind",
			communityCards: []string{"SA", "D3", "H2", "C8", "SJ"},
			player1Hole:    []string{"HJ", "SJ"},
			player2Hole:    []string{"C3", "H3"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 11 - Three of a Kind",
			handType:       "Three of a Kind",
			communityCards: []string{"SA", "D3", "H3", "C8", "SJ"},
			player1Hole:    []string{"C3", "S2"},
			player2Hole:    []string{"S3", "H2"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 12 - Three of a Kind",
			handType:       "Three of a Kind",
			communityCards: []string{"HA", "SA", "DA", "H3", "HT"},
			player1Hole:    []string{"S2", "S5"},
			player2Hole:    []string{"H2", "SK"},
			expectedResult: "player2",
		},
		{
			name:           "Excel Test 13 - Straight",
			handType:       "Straight",
			communityCards: []string{"H3", "S4", "C5", "S6", "HT"},
			player1Hole:    []string{"D7", "HA"},
			player2Hole:    []string{"H2", "SA"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 14 - Straight",
			handType:       "Straight",
			communityCards: []string{"H3", "S4", "C5", "S6", "HT"},
			player1Hole:    []string{"D7", "HA"},
			player2Hole:    []string{"H7", "SA"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 15 - Straight",
			handType:       "Straight",
			communityCards: []string{"H2", "H3", "S4", "C5", "HT"},
			player1Hole:    []string{"HA", "S3"},
			player2Hole:    []string{"H6", "SA"},
			expectedResult: "player2",
		},
		{
			name:           "Excel Test 16 - Flush",
			handType:       "Flush",
			communityCards: []string{"D3", "D6", "DT", "C5", "HQ"},
			player1Hole:    []string{"DK", "DA"},
			player2Hole:    []string{"D2", "DQ"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 17 - Flush",
			handType:       "Flush",
			communityCards: []string{"D3", "D6", "DT", "DJ", "DK"},
			player1Hole:    []string{"C3", "HA"},
			player2Hole:    []string{"S9", "HJ"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 18 - Flush",
			handType:       "Flush",
			communityCards: []string{"D3", "D6", "DT", "C5", "HQ"},
			player1Hole:    []string{"D2", "D5"},
			player2Hole:    []string{"DJ", "DA"},
			expectedResult: "player2",
		},
		{
			name:           "Excel Test 19 - Full House",
			handType:       "Full House",
			communityCards: []string{"HQ", "SQ", "HT", "DT", "C3"},
			player1Hole:    []string{"DQ", "C2"},
			player2Hole:    []string{"CT", "C4"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 20 - Full House",
			handType:       "Full House",
			communityCards: []string{"SA", "HQ", "SQ", "HT", "D8"},
			player1Hole:    []string{"HA", "DQ"},
			player2Hole:    []string{"DA", "CQ"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 21 - Full House",
			handType:       "Full House",
			communityCards: []string{"HQ", "SQ", "HT", "DT", "C3"},
			player1Hole:    []string{"ST", "C2"},
			player2Hole:    []string{"CQ", "C4"},
			expectedResult: "player2",
		},
		{
			name:           "Excel Test 22 - Four of a Kind",
			handType:       "Four of a Kind",
			communityCards: []string{"HT", "ST", "CT", "DT", "HK"},
			player1Hole:    []string{"HA", "S7"},
			player2Hole:    []string{"DJ", "C5"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 23 - Four of a Kind",
			handType:       "Four of a Kind",
			communityCards: []string{"S5", "D5", "C5", "H5", "HA"},
			player1Hole:    []string{"CT", "HT"},
			player2Hole:    []string{"C4", "SQ"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 24 - Four of a Kind",
			handType:       "Four of a Kind",
			communityCards: []string{"HT", "ST", "CT", "DT", "S8"},
			player1Hole:    []string{"C2", "C3"},
			player2Hole:    []string{"C5", "HK"},
			expectedResult: "player2",
		},
		{
			name:           "Excel Test 25 - Straight Flush",
			handType:       "Straight Flush",
			communityCards: []string{"H3", "H4", "H5", "H6", "HT"},
			player1Hole:    []string{"H7", "HA"},
			player2Hole:    []string{"H2", "SA"},
			expectedResult: "player1",
		},
		{
			name:           "Excel Test 26 - Straight Flush",
			handType:       "Straight Flush",
			communityCards: []string{"H3", "H4", "H5", "H6", "H7"},
			player1Hole:    []string{"HA", "ST"},
			player2Hole:    []string{"CQ", "D6"},
			expectedResult: "tie",
		},
		{
			name:           "Excel Test 27 - Straight Flush",
			handType:       "Straight Flush",
			communityCards: []string{"S7", "S8", "S9", "ST", "DK"},
			player1Hole:    []string{"S6", "C2"},
			player2Hole:    []string{"SJ", "D5"},
			expectedResult: "player2",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			p1Hole, err := ParseCards(tc.player1Hole)
			if err != nil {
				t.Fatalf("Failed to parse player 1 hole cards: %v", err)
			}
			
			p2Hole, err := ParseCards(tc.player2Hole)
			if err != nil {
				t.Fatalf("Failed to parse player 2 hole cards: %v", err)
			}
			
			community, err := ParseCards(tc.communityCards)
			if err != nil {
				t.Fatalf("Failed to parse community cards: %v", err)
			}
			
			hand1 := EvaluateBestHand(p1Hole, community)
			hand2 := EvaluateBestHand(p2Hole, community)
			
			winner := 0
			if hand1.Value > hand2.Value {
				winner = 1
			} else if hand2.Value > hand1.Value {
				winner = 2
			}
			
			var actualResult string
			if winner == 1 {
				actualResult = "player1"
			} else if winner == 2 {
				actualResult = "player2"
			} else {
				actualResult = "tie"
			}
			
			if actualResult != tc.expectedResult {
				t.Errorf("Expected %s, got %s", tc.expectedResult, actualResult)
				t.Logf("Player 1: %s (value: %d)", hand1.Description, hand1.Value)
				t.Logf("Player 2: %s (value: %d)", hand2.Description, hand2.Value)
				t.Logf("Hand type: %s", tc.handType)
			}
		})
	}
}
