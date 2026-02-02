package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "temperature-converter/pb"
)

// server implements the TemperatureConverter service
type server struct {
	pb.UnimplementedTemperatureConverterServer
}

// ConvertCelsiusToFahrenheit converts Celsius to Fahrenheit
func (s *server) ConvertCelsiusToFahrenheit(ctx context.Context, req *pb.CelsiusRequest) (*pb.TemperatureResponse, error) {
	celsius := req.GetCelsius()
	fahrenheit := (celsius * 9.0 / 5.0) + 32.0

	return &pb.TemperatureResponse{
		Celsius:    celsius,
		Fahrenheit: fahrenheit,
	}, nil
}

// ConvertFahrenheitToCelsius converts Fahrenheit to Celsius
func (s *server) ConvertFahrenheitToCelsius(ctx context.Context, req *pb.FahrenheitRequest) (*pb.TemperatureResponse, error) {
	fahrenheit := req.GetFahrenheit()
	celsius := (fahrenheit - 32.0) * 5.0 / 9.0

	return &pb.TemperatureResponse{
		Celsius:    celsius,
		Fahrenheit: fahrenheit,
	}, nil
}

// REST handlers that call gRPC service
type ConversionRequest struct {
	Celsius    float64 `json:"celsius"`
	Fahrenheit float64 `json:"fahrenheit"`
}

type ConversionResponse struct {
	Celsius    float64 `json:"celsius"`
	Fahrenheit float64 `json:"fahrenheit"`
}

func celsiusToFahrenheitHandler(grpcClient pb.TemperatureConverterClient) http.HandlerFunc {
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

		var req ConversionRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Call gRPC service
		grpcReq := &pb.CelsiusRequest{Celsius: req.Celsius}
		resp, err := grpcClient.ConvertCelsiusToFahrenheit(context.Background(), grpcReq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		response := ConversionResponse{
			Celsius:    resp.Celsius,
			Fahrenheit: resp.Fahrenheit,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

func fahrenheitToCelsiusHandler(grpcClient pb.TemperatureConverterClient) http.HandlerFunc {
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

		var req ConversionRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Call gRPC service
		grpcReq := &pb.FahrenheitRequest{Fahrenheit: req.Fahrenheit}
		resp, err := grpcClient.ConvertFahrenheitToCelsius(context.Background(), grpcReq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		response := ConversionResponse{
			Celsius:    resp.Celsius,
			Fahrenheit: resp.Fahrenheit,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

func main() {
	grpcPort := ":8081"
	httpPort := ":8080"

	// Start gRPC server in a goroutine
	go func() {
		lis, err := net.Listen("tcp", grpcPort)
		if err != nil {
			log.Fatalf("Failed to listen: %v", err)
		}

		grpcServer := grpc.NewServer()
		pb.RegisterTemperatureConverterServer(grpcServer, &server{})
		pb.RegisterPokerEvaluatorServer(grpcServer, &pokerServer{})

		fmt.Printf("gRPC server starting on port %s\n", grpcPort)
		fmt.Println("gRPC endpoints:")
		fmt.Println("  TemperatureConverter:")
		fmt.Println("    ConvertCelsiusToFahrenheit")
		fmt.Println("    ConvertFahrenheitToCelsius")
		fmt.Println("  PokerEvaluator:")
		fmt.Println("    EvaluateHand")
		fmt.Println("    CompareHands")
		fmt.Println("    CalculateWinProbability")

		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("Failed to serve gRPC: %v", err)
		}
	}()

	// Wait for gRPC server to be ready
	time.Sleep(1 * time.Second)

	// Connect to gRPC server
	conn, err := grpc.NewClient("localhost"+grpcPort, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("Failed to connect to gRPC server: %v", err)
	}
	defer conn.Close()

	tempGrpcClient := pb.NewTemperatureConverterClient(conn)
	pokerGrpcClient := pb.NewPokerEvaluatorClient(conn)

	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Set up REST API that calls gRPC
	// Temperature converter endpoints
	http.HandleFunc("/convert", celsiusToFahrenheitHandler(tempGrpcClient))
	http.HandleFunc("/convert-fahrenheit", fahrenheitToCelsiusHandler(tempGrpcClient))
	
	// Poker endpoints
	http.HandleFunc("/poker/evaluate-hand", evaluateHandHandler(pokerGrpcClient))
	http.HandleFunc("/poker/compare-hands", compareHandsHandler(pokerGrpcClient))
	http.HandleFunc("/poker/calculate-probability", calculateProbabilityHandler(pokerGrpcClient))

	fmt.Printf("REST API (gRPC gateway) starting on port %s\n", httpPort)
	fmt.Println("REST endpoints (calling gRPC internally):")
	fmt.Println("  Temperature Converter:")
	fmt.Println("    POST http://localhost:8080/convert")
	fmt.Println("    POST http://localhost:8080/convert-fahrenheit")
	fmt.Println("  Poker Evaluator:")
	fmt.Println("    POST http://localhost:8080/poker/evaluate-hand")
	fmt.Println("    POST http://localhost:8080/poker/compare-hands")
	fmt.Println("    POST http://localhost:8080/poker/calculate-probability")

	if err := http.ListenAndServe(httpPort, nil); err != nil {
		log.Fatalf("Failed to serve HTTP: %v", err)
	}
}
