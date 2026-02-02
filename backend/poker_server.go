package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	pb "temperature-converter/pb"
	"temperature-converter/poker"
)

// pokerServer implements the PokerEvaluator service
type pokerServer struct {
	pb.UnimplementedPokerEvaluatorServer
}

// EvaluateHand evaluates the best hand from 2 hole cards + 5 community cards
func (s *pokerServer) EvaluateHand(ctx context.Context, req *pb.EvaluateHandRequest) (*pb.EvaluateHandResponse, error) {
	// Parse hole cards
	holeCards, err := poker.ParseCards(req.HoleCards)
	if err != nil {
		return nil, fmt.Errorf("invalid hole cards: %v", err)
	}
	if len(holeCards) != 2 {
		return nil, fmt.Errorf("must provide exactly 2 hole cards")
	}

	// Parse community cards
	communityCards, err := poker.ParseCards(req.CommunityCards)
	if err != nil {
		return nil, fmt.Errorf("invalid community cards: %v", err)
	}
	if len(communityCards) != 5 {
		return nil, fmt.Errorf("must provide exactly 5 community cards")
	}

	// Evaluate hand
	hand := poker.EvaluateBestHand(holeCards, communityCards)

	// Convert cards to strings
	bestFiveCards := make([]string, len(hand.Cards))
	for i, card := range hand.Cards {
		bestFiveCards[i] = poker.CardToString(card)
	}

	return &pb.EvaluateHandResponse{
		BestHand:      hand.Description,
		HandValue:     hand.Value,
		BestFiveCards: bestFiveCards,
	}, nil
}

// CompareHands compares two hands and determines the winner
func (s *pokerServer) CompareHands(ctx context.Context, req *pb.CompareHandsRequest) (*pb.CompareHandsResponse, error) {
	// Parse player 1 cards
	player1HoleCards, err := poker.ParseCards(req.Player1HoleCards)
	if err != nil {
		return nil, fmt.Errorf("invalid player 1 hole cards: %v", err)
	}
	if len(player1HoleCards) != 2 {
		return nil, fmt.Errorf("player 1 must have exactly 2 hole cards")
	}

	player1CommunityCards, err := poker.ParseCards(req.Player1CommunityCards)
	if err != nil {
		return nil, fmt.Errorf("invalid player 1 community cards: %v", err)
	}
	if len(player1CommunityCards) != 5 {
		return nil, fmt.Errorf("player 1 must have exactly 5 community cards")
	}

	// Parse player 2 cards
	player2HoleCards, err := poker.ParseCards(req.Player2HoleCards)
	if err != nil {
		return nil, fmt.Errorf("invalid player 2 hole cards: %v", err)
	}
	if len(player2HoleCards) != 2 {
		return nil, fmt.Errorf("player 2 must have exactly 2 hole cards")
	}

	player2CommunityCards, err := poker.ParseCards(req.Player2CommunityCards)
	if err != nil {
		return nil, fmt.Errorf("invalid player 2 community cards: %v", err)
	}
	if len(player2CommunityCards) != 5 {
		return nil, fmt.Errorf("player 2 must have exactly 5 community cards")
	}

	// Evaluate both hands
	hand1 := poker.EvaluateBestHand(player1HoleCards, player1CommunityCards)
	hand2 := poker.EvaluateBestHand(player2HoleCards, player2CommunityCards)

	// Convert cards to strings
	bestFiveCards1 := make([]string, len(hand1.Cards))
	for i, card := range hand1.Cards {
		bestFiveCards1[i] = poker.CardToString(card)
	}

	bestFiveCards2 := make([]string, len(hand2.Cards))
	for i, card := range hand2.Cards {
		bestFiveCards2[i] = poker.CardToString(card)
	}

	player1Response := &pb.EvaluateHandResponse{
		BestHand:      hand1.Description,
		HandValue:     hand1.Value,
		BestFiveCards: bestFiveCards1,
	}

	player2Response := &pb.EvaluateHandResponse{
		BestHand:      hand2.Description,
		HandValue:     hand2.Value,
		BestFiveCards: bestFiveCards2,
	}

	// Determine winner
	winner := 0
	if hand1.Value > hand2.Value {
		winner = 1
	} else if hand2.Value > hand1.Value {
		winner = 2
	}

	return &pb.CompareHandsResponse{
		Player1Hand: player1Response,
		Player2Hand: player2Response,
		Winner:      int32(winner),
	}, nil
}

// CalculateWinProbability calculates win probability using Monte Carlo simulation
func (s *pokerServer) CalculateWinProbability(ctx context.Context, req *pb.ProbabilityRequest) (*pb.ProbabilityResponse, error) {
	// Parse hole cards
	holeCards, err := poker.ParseCards(req.HoleCards)
	if err != nil {
		return nil, fmt.Errorf("invalid hole cards: %v", err)
	}
	if len(holeCards) != 2 {
		return nil, fmt.Errorf("must provide exactly 2 hole cards")
	}

	// Parse community cards (0, 3, 4, or 5)
	communityCards, err := poker.ParseCards(req.CommunityCards)
	if err != nil {
		return nil, fmt.Errorf("invalid community cards: %v", err)
	}
	if len(communityCards) != 0 && len(communityCards) != 3 && len(communityCards) != 4 && len(communityCards) != 5 {
		return nil, fmt.Errorf("must provide 0, 3, 4, or 5 community cards")
	}

	numPlayers := int(req.NumPlayers)
	if numPlayers < 2 {
		return nil, fmt.Errorf("must have at least 2 players")
	}

	numSimulations := int(req.NumSimulations)
	if numSimulations < 1 {
		return nil, fmt.Errorf("must run at least 1 simulation")
	}

	// Calculate probability
	winProb, tieProb := poker.CalculateWinProbability(holeCards, communityCards, numPlayers, numSimulations)

	return &pb.ProbabilityResponse{
		WinProbability: winProb,
		TieProbability: tieProb,
	}, nil
}

// REST request/response types
type EvaluateHandRESTRequest struct {
	HoleCards      []string `json:"hole_cards"`
	CommunityCards []string `json:"community_cards"`
}

type EvaluateHandRESTResponse struct {
	BestHand      string   `json:"best_hand"`
	HandValue     int32    `json:"hand_value"`
	BestFiveCards []string `json:"best_five_cards"`
}

type CompareHandsRESTRequest struct {
	Player1HoleCards      []string `json:"player1_hole_cards"`
	Player1CommunityCards []string `json:"player1_community_cards"`
	Player2HoleCards      []string `json:"player2_hole_cards"`
	Player2CommunityCards []string `json:"player2_community_cards"`
}

type CompareHandsRESTResponse struct {
	Player1Hand EvaluateHandRESTResponse `json:"player1_hand"`
	Player2Hand EvaluateHandRESTResponse `json:"player2_hand"`
	Winner      int32                    `json:"winner"`
}

type ProbabilityRESTRequest struct {
	HoleCards      []string `json:"hole_cards"`
	CommunityCards []string `json:"community_cards"`
	NumPlayers     int32    `json:"num_players"`
	NumSimulations int32    `json:"num_simulations"`
}

type ProbabilityRESTResponse struct {
	WinProbability float64 `json:"win_probability"`
	TieProbability float64 `json:"tie_probability"`
}

// REST handlers
func evaluateHandHandler(grpcClient pb.PokerEvaluatorClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req EvaluateHandRESTRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Call gRPC service
		grpcReq := &pb.EvaluateHandRequest{
			HoleCards:      req.HoleCards,
			CommunityCards: req.CommunityCards,
		}
		resp, err := grpcClient.EvaluateHand(context.Background(), grpcReq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		response := EvaluateHandRESTResponse{
			BestHand:      resp.BestHand,
			HandValue:     resp.HandValue,
			BestFiveCards: resp.BestFiveCards,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

func compareHandsHandler(grpcClient pb.PokerEvaluatorClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req CompareHandsRESTRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Call gRPC service
		grpcReq := &pb.CompareHandsRequest{
			Player1HoleCards:      req.Player1HoleCards,
			Player1CommunityCards: req.Player1CommunityCards,
			Player2HoleCards:      req.Player2HoleCards,
			Player2CommunityCards: req.Player2CommunityCards,
		}
		resp, err := grpcClient.CompareHands(context.Background(), grpcReq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		response := CompareHandsRESTResponse{
			Player1Hand: EvaluateHandRESTResponse{
				BestHand:      resp.Player1Hand.BestHand,
				HandValue:     resp.Player1Hand.HandValue,
				BestFiveCards: resp.Player1Hand.BestFiveCards,
			},
			Player2Hand: EvaluateHandRESTResponse{
				BestHand:      resp.Player2Hand.BestHand,
				HandValue:     resp.Player2Hand.HandValue,
				BestFiveCards: resp.Player2Hand.BestFiveCards,
			},
			Winner: resp.Winner,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

func calculateProbabilityHandler(grpcClient pb.PokerEvaluatorClient) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req ProbabilityRESTRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Call gRPC service
		grpcReq := &pb.ProbabilityRequest{
			HoleCards:      req.HoleCards,
			CommunityCards: req.CommunityCards,
			NumPlayers:     req.NumPlayers,
			NumSimulations: req.NumSimulations,
		}
		resp, err := grpcClient.CalculateWinProbability(context.Background(), grpcReq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		response := ProbabilityRESTResponse{
			WinProbability: resp.WinProbability,
			TieProbability: resp.TieProbability,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

