package poker

import (
	"fmt"
	"math/rand"
	"sort"
	"strings"
	"time"
)

// Suit represents a card suit
type Suit int

const (
	Hearts Suit = iota
	Diamonds
	Clubs
	Spades
)

// Rank represents a card rank
type Rank int

const (
	Two Rank = iota
	Three
	Four
	Five
	Six
	Seven
	Eight
	Nine
	Ten
	Jack
	Queen
	King
	Ace
)

// Card represents a playing card
type Card struct {
	Suit Suit
	Rank Rank
}

// HandType represents the type of poker hand
type HandType int

const (
	HighCard HandType = iota
	Pair
	TwoPair
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
	RoyalFlush
)

// Hand represents an evaluated poker hand
type Hand struct {
	Type        HandType
	Value       int32
	Description string
	Cards       []Card
}

// ParseCard parses a card string (e.g., "HA" for Heart-Ace, "S7" for Spade-7)
func ParseCard(cardStr string) (Card, error) {
	if len(cardStr) != 2 {
		return Card{}, fmt.Errorf("invalid card format: %s (must be 2 characters)", cardStr)
	}

	cardStr = strings.ToUpper(cardStr)
	
	// Parse suit (first character)
	var suit Suit
	switch cardStr[0] {
	case 'H':
		suit = Hearts
	case 'D':
		suit = Diamonds
	case 'C':
		suit = Clubs
	case 'S':
		suit = Spades
	default:
		return Card{}, fmt.Errorf("invalid suit: %c (must be H, D, C, or S)", cardStr[0])
	}

	// Parse rank (second character)
	var rank Rank
	switch cardStr[1] {
	case '2':
		rank = Two
	case '3':
		rank = Three
	case '4':
		rank = Four
	case '5':
		rank = Five
	case '6':
		rank = Six
	case '7':
		rank = Seven
	case '8':
		rank = Eight
	case '9':
		rank = Nine
	case 'T':
		rank = Ten
	case 'J':
		rank = Jack
	case 'Q':
		rank = Queen
	case 'K':
		rank = King
	case 'A':
		rank = Ace
	default:
		return Card{}, fmt.Errorf("invalid rank: %c (must be 2-9, T, J, Q, K, or A)", cardStr[1])
	}

	return Card{Suit: suit, Rank: rank}, nil
}

// ParseCards parses multiple card strings
func ParseCards(cardStrs []string) ([]Card, error) {
	cards := make([]Card, 0, len(cardStrs))
	for _, cardStr := range cardStrs {
		card, err := ParseCard(cardStr)
		if err != nil {
			return nil, err
		}
		cards = append(cards, card)
	}
	return cards, nil
}

// EvaluateBestHand evaluates the best 5-card hand from 7 cards (2 hole + 5 community)
func EvaluateBestHand(holeCards, communityCards []Card) Hand {
	allCards := append(holeCards, communityCards...)
	if len(allCards) != 7 {
		return Hand{Type: HighCard, Value: 0, Description: "Invalid number of cards"}
	}

	// Try all combinations of 5 cards from 7
	bestHand := Hand{Type: HighCard, Value: 0, Cards: make([]Card, 5)}
	
	// Generate all combinations of 5 cards from 7
	for i := 0; i < 7; i++ {
		for j := i + 1; j < 7; j++ {
			fiveCards := make([]Card, 0, 5)
			for k := 0; k < 7; k++ {
				if k != i && k != j {
					fiveCards = append(fiveCards, allCards[k])
				}
			}
			
			hand := evaluateFiveCards(fiveCards)
			if compareHands(hand, bestHand) > 0 {
				// Make a copy of the hand to preserve the cards
				bestHand = Hand{
					Type:        hand.Type,
					Value:       hand.Value,
					Description: hand.Description,
					Cards:       make([]Card, len(hand.Cards)),
				}
				copy(bestHand.Cards, hand.Cards)
			}
		}
	}

	return bestHand
}

// evaluateFiveCards evaluates a 5-card hand
func evaluateFiveCards(cards []Card) Hand {
	if len(cards) != 5 {
		return Hand{Type: HighCard, Value: 0, Description: "Invalid number of cards"}
	}

	// Sort cards by rank
	sortedCards := make([]Card, 5)
	copy(sortedCards, cards)
	sort.Slice(sortedCards, func(i, j int) bool {
		return sortedCards[i].Rank < sortedCards[j].Rank
	})

	// Count ranks and suits
	rankCount := make(map[Rank]int)
	suitCount := make(map[Suit]int)
	for _, card := range sortedCards {
		rankCount[card.Rank]++
		suitCount[card.Suit]++
	}

	isFlush := len(suitCount) == 1
	isStraight := isStraightSequence(sortedCards)

	// Check for Royal Flush
	if isFlush && isStraight && sortedCards[0].Rank == Ten && sortedCards[4].Rank == Ace {
		return Hand{
			Type:        RoyalFlush,
			Value:       int32(RoyalFlush)*10000 + int32(sortedCards[4].Rank),
			Description: "Royal Flush",
			Cards:       sortedCards,
		}
	}

	// Check for Straight Flush
	if isFlush && isStraight {
		// For wheel (A-2-3-4-5), use 5 as the high card, not Ace
		highCard := sortedCards[4].Rank
		if sortedCards[0].Rank == Two && sortedCards[4].Rank == Ace {
			highCard = Five
		}
		return Hand{
			Type:        StraightFlush,
			Value:       int32(StraightFlush)*10000 + int32(highCard),
			Description: "Straight Flush",
			Cards:       sortedCards,
		}
	}

	// Count pairs, trips, quads
	var pairs []Rank
	var trips Rank = -1
	var quads Rank = -1
	var hasTrips bool
	var hasQuads bool

	for rank, count := range rankCount {
		switch count {
		case 2:
			pairs = append(pairs, rank)
		case 3:
			trips = rank
			hasTrips = true
		case 4:
			quads = rank
			hasQuads = true
		}
	}

	// Check for Four of a Kind
	if hasQuads {
		var kicker Rank
		for _, card := range sortedCards {
			if card.Rank != quads {
				kicker = card.Rank
				break
			}
		}
		return Hand{
			Type:        FourOfAKind,
			Value:       int32(FourOfAKind)*10000 + int32(quads)*100 + int32(kicker),
			Description: "Four of a Kind",
			Cards:       sortedCards,
		}
	}

	// Check for Full House
	if hasTrips && len(pairs) > 0 {
		sort.Slice(pairs, func(i, j int) bool {
			return pairs[i] > pairs[j]
		})
		return Hand{
			Type:        FullHouse,
			Value:       int32(FullHouse)*10000 + int32(trips)*100 + int32(pairs[0]),
			Description: "Full House",
			Cards:       sortedCards,
		}
	}

	// Check for Flush
	if isFlush {
		value := int32(Flush) * 10000
		for i := 4; i >= 0; i-- {
			value = value*100 + int32(sortedCards[i].Rank)
		}
		return Hand{
			Type:        Flush,
			Value:       value,
			Description: "Flush",
			Cards:       sortedCards,
		}
	}

	// Check for Straight
	if isStraight {
		// For wheel (A-2-3-4-5), use 5 as the high card, not Ace
		highCard := sortedCards[4].Rank
		if sortedCards[0].Rank == Two && sortedCards[4].Rank == Ace {
			highCard = Five
		}
		return Hand{
			Type:        Straight,
			Value:       int32(Straight)*10000 + int32(highCard),
			Description: "Straight",
			Cards:       sortedCards,
		}
	}

	// Check for Three of a Kind
	if hasTrips {
		kickers := make([]Rank, 0)
		for _, card := range sortedCards {
			if card.Rank != trips {
				kickers = append(kickers, card.Rank)
			}
		}
		sort.Slice(kickers, func(i, j int) bool {
			return kickers[i] > kickers[j]
		})
		return Hand{
			Type:        ThreeOfAKind,
			Value:       int32(ThreeOfAKind)*10000 + int32(trips)*100 + int32(kickers[0])*10 + int32(kickers[1]),
			Description: "Three of a Kind",
			Cards:       sortedCards,
		}
	}

	// Check for Two Pair
	if len(pairs) >= 2 {
		sort.Slice(pairs, func(i, j int) bool {
			return pairs[i] > pairs[j]
		})
		var kicker Rank
		for _, card := range sortedCards {
			if card.Rank != pairs[0] && card.Rank != pairs[1] {
				kicker = card.Rank
				break
			}
		}
		return Hand{
			Type:        TwoPair,
			Value:       int32(TwoPair)*10000 + int32(pairs[0])*1000 + int32(pairs[1])*100 + int32(kicker),
			Description: "Two Pair",
			Cards:       sortedCards,
		}
	}

	// Check for Pair
	if len(pairs) == 1 {
		kickers := make([]Rank, 0)
		for _, card := range sortedCards {
			if card.Rank != pairs[0] {
				kickers = append(kickers, card.Rank)
			}
		}
		sort.Slice(kickers, func(i, j int) bool {
			return kickers[i] > kickers[j]
		})
		return Hand{
			Type:        Pair,
			Value:       int32(Pair)*10000 + int32(pairs[0])*1000 + int32(kickers[0])*100 + int32(kickers[1])*10 + int32(kickers[2]),
			Description: "Pair",
			Cards:       sortedCards,
		}
	}

	// High Card
	value := int32(HighCard) * 10000
	for i := 4; i >= 0; i-- {
		value = value*100 + int32(sortedCards[i].Rank)
	}
	return Hand{
		Type:        HighCard,
		Value:       value,
		Description: "High Card",
		Cards:       sortedCards,
	}
}

// isStraightSequence checks if 5 cards form a straight
func isStraightSequence(cards []Card) bool {
	// Check for regular straight
	isRegularStraight := true
	for i := 1; i < 5; i++ {
		if cards[i].Rank != cards[i-1].Rank+1 {
			isRegularStraight = false
			break
		}
	}

	// Check for A-2-3-4-5 straight (wheel)
	isWheel := cards[0].Rank == Two &&
		cards[1].Rank == Three &&
		cards[2].Rank == Four &&
		cards[3].Rank == Five &&
		cards[4].Rank == Ace

	return isRegularStraight || isWheel
}

// compareHands compares two hands. Returns 1 if hand1 > hand2, -1 if hand1 < hand2, 0 if equal
func compareHands(hand1, hand2 Hand) int {
	if hand1.Value > hand2.Value {
		return 1
	} else if hand1.Value < hand2.Value {
		return -1
	}
	return 0
}

// GetDeck returns a full deck of 52 cards
func GetDeck() []Card {
	deck := make([]Card, 0, 52)
	for suit := Hearts; suit <= Spades; suit++ {
		for rank := Two; rank <= Ace; rank++ {
			deck = append(deck, Card{Suit: suit, Rank: rank})
		}
	}
	return deck
}

// RemoveCards removes specified cards from the deck
func RemoveCards(deck []Card, toRemove []Card) []Card {
	result := make([]Card, 0)
	for _, card := range deck {
		shouldRemove := false
		for _, removeCard := range toRemove {
			if card.Suit == removeCard.Suit && card.Rank == removeCard.Rank {
				shouldRemove = true
				break
			}
		}
		if !shouldRemove {
			result = append(result, card)
		}
	}
	return result
}

// ShuffleDeck shuffles a deck of cards
func ShuffleDeck(deck []Card) []Card {
	shuffled := make([]Card, len(deck))
	copy(shuffled, deck)
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	r.Shuffle(len(shuffled), func(i, j int) {
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	})
	return shuffled
}

// CalculateWinProbability calculates win probability using Monte Carlo simulation
func CalculateWinProbability(holeCards []Card, communityCards []Card, numPlayers int, numSimulations int) (float64, float64) {
	if numPlayers < 2 {
		return 0.0, 0.0
	}

	wins := 0
	ties := 0

	// Create initial deck and remove known cards
	deck := GetDeck()
	knownCards := append(holeCards, communityCards...)
	deck = RemoveCards(deck, knownCards)

	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	for sim := 0; sim < numSimulations; sim++ {
		// Shuffle remaining deck
		shuffled := make([]Card, len(deck))
		copy(shuffled, deck)
		r.Shuffle(len(shuffled), func(i, j int) {
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		})

		// Complete community cards if needed
		simCommunityCards := make([]Card, len(communityCards))
		copy(simCommunityCards, communityCards)
		
		cardsNeeded := 5 - len(communityCards)
		for i := 0; i < cardsNeeded; i++ {
			simCommunityCards = append(simCommunityCards, shuffled[i])
		}

		// Deal cards to other players
		otherPlayersCards := make([][]Card, numPlayers-1)
		cardIndex := cardsNeeded
		for i := 0; i < numPlayers-1; i++ {
			otherPlayersCards[i] = []Card{shuffled[cardIndex], shuffled[cardIndex+1]}
			cardIndex += 2
		}

		// Evaluate our hand
		ourHand := EvaluateBestHand(holeCards, simCommunityCards)

		// Evaluate other players' hands
		bestOtherHand := Hand{Type: HighCard, Value: 0}
		for _, playerCards := range otherPlayersCards {
			playerHand := EvaluateBestHand(playerCards, simCommunityCards)
			if compareHands(playerHand, bestOtherHand) > 0 {
				bestOtherHand = playerHand
			}
		}

		// Count wins and ties
		comparison := compareHands(ourHand, bestOtherHand)
		if comparison > 0 {
			wins++
		} else if comparison == 0 {
			// Check if we tie with all other players
			allTie := true
			for _, playerCards := range otherPlayersCards {
				playerHand := EvaluateBestHand(playerCards, simCommunityCards)
				if compareHands(ourHand, playerHand) != 0 {
					allTie = false
					break
				}
			}
			if allTie {
				ties++
			}
		}
	}

	winProb := float64(wins) / float64(numSimulations)
	tieProb := float64(ties) / float64(numSimulations)

	return winProb, tieProb
}

// CardToString converts a Card back to string format
func CardToString(card Card) string {
	suitStr := ""
	switch card.Suit {
	case Hearts:
		suitStr = "H"
	case Diamonds:
		suitStr = "D"
	case Clubs:
		suitStr = "C"
	case Spades:
		suitStr = "S"
	}

	rankStr := ""
	switch card.Rank {
	case Two:
		rankStr = "2"
	case Three:
		rankStr = "3"
	case Four:
		rankStr = "4"
	case Five:
		rankStr = "5"
	case Six:
		rankStr = "6"
	case Seven:
		rankStr = "7"
	case Eight:
		rankStr = "8"
	case Nine:
		rankStr = "9"
	case Ten:
		rankStr = "T"
	case Jack:
		rankStr = "J"
	case Queen:
		rankStr = "Q"
	case King:
		rankStr = "K"
	case Ace:
		rankStr = "A"
	}

	return suitStr + rankStr
}

