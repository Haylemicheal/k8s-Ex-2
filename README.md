# Poker Calculator Application

A modern, distributed Texas Hold'em poker hand evaluator and probability calculator built with **Go (gRPC)** backend and **Flutter** web frontend, designed for deployment on Google Kubernetes Engine (GKE).

## 🌟 Features

- **Hand Evaluation**: Evaluate the best 5-card hand from 2 hole cards + 5 community cards
- **Hand Comparison**: Compare two players' hands and determine the winner
- **Win Probability**: Calculate win probability using Monte Carlo simulation
- **Card Format**: Simple 2-character format (e.g., `HA` for Heart-Ace, `S7` for Spade-7)
- **Modern Architecture**: gRPC microservice backend with REST gateway
- **Beautiful UI**: Responsive Flutter web application with smooth animations
- **Production Ready**: Docker containerized, Kubernetes orchestrated
- **Health Checks**: Built-in health monitoring for reliability

## 🏗️ Architecture

```
┌─────────────────┐
│  Flutter Web    │
│   (Frontend)    │
│   Port: 80      │
└────────┬────────┘
         │ HTTP/REST
         ▼
┌─────────────────┐
│  gRPC-Gateway   │
│   Port: 8080    │
└────────┬────────┘
         │ gRPC
         ▼
┌─────────────────┐
│  gRPC Server    │
│   Port: 8081    │
│  (Backend)      │
└─────────────────┘
```

### Components

- **Backend**: Go-based gRPC service with REST gateway for HTTP compatibility
- **Frontend**: Flutter web application served via Nginx
- **Protocol**: gRPC for internal communication, REST for frontend
- **Deployment**: Kubernetes for orchestration and scaling

## 📋 Prerequisites

### Local Development
- **Docker** and **Docker Compose**
- **Go** 1.24+ (for local backend development)
- **Flutter** SDK (for local frontend development)

### Cloud Deployment
- **Google Cloud SDK (gcloud)** installed and configured
- **kubectl** installed
- **Docker** installed
- **Google Cloud Project** with billing enabled
- **GKE API** enabled

## 🚀 Quick Start

### Local Development (Without Docker)

#### Backend

```bash
cd backend

# Install dependencies
go mod download

# Generate gRPC code (if proto file changed)
export PATH=$PATH:$(go env GOPATH)/bin
protoc --go_out=. --go-grpc_out=. poker.proto

# Run the server
go run main.go poker_server.go
```

#### Frontend

```bash
cd poker_calculator_flutter

# Install dependencies
flutter pub get

# Run in development mode
flutter run -d chrome

# Build for web
flutter build web --release --dart-define=API_URL=http://localhost:8080
```

## 📡 API Documentation

### REST Endpoints

The backend exposes REST endpoints via gRPC-Gateway:

#### Evaluate Hand
```http
POST /poker/evaluate-hand
Content-Type: application/json

{
  "hole_cards": ["HA", "SA"],
  "community_cards": ["DA", "CA", "HK", "HQ", "HJ"]
}
```

**Response:**
```json
{
  "best_hand": "Royal Flush",
  "hand_value": 90012,
  "best_five_cards": ["HA", "SA", "DA", "CA", "HK"]
}
```

#### Compare Hands
```http
POST /poker/compare-hands
Content-Type: application/json

{
  "player1_hole_cards": ["HA", "SA"],
  "player1_community_cards": ["DA", "CA", "HK", "HQ", "HJ"],
  "player2_hole_cards": ["HK", "HQ"],
  "player2_community_cards": ["DA", "CA", "HA", "SA", "HJ"]
}
```

**Response:**
```json
{
  "player1_hand": {
    "best_hand": "Royal Flush",
    "hand_value": 90012,
    "best_five_cards": ["HA", "SA", "DA", "CA", "HK"]
  },
  "player2_hand": {
    "best_hand": "Straight",
    "hand_value": 40012,
    "best_five_cards": ["HK", "HQ", "HJ", "HA", "SA"]
  },
  "winner": 1
}
```

#### Calculate Win Probability
```http
POST /poker/calculate-probability
Content-Type: application/json

{
  "hole_cards": ["HA", "SA"],
  "community_cards": [],
  "num_players": 4,
  "num_simulations": 10000
}
```

**Response:**
```json
{
  "win_probability": 0.8542,
  "tie_probability": 0.0123
}
```

### gRPC Service

The backend also exposes a gRPC service on port 8081:

```protobuf
service PokerEvaluator {
  rpc EvaluateHand(EvaluateHandRequest) returns (EvaluateHandResponse);
  rpc CompareHands(CompareHandsRequest) returns (CompareHandsResponse);
  rpc CalculateWinProbability(ProbabilityRequest) returns (ProbabilityResponse);
}
```

## ☁️ Deployment to Google Kubernetes Engine

### Quick Deployment

1. **Set up your GCP project**:
   ```bash
   export PROJECT_ID=your-project-id
   export REGION=us-central1
   
   gcloud config set project $PROJECT_ID
   gcloud services enable container.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   ```

2. **Deploy using the automated script**:
   ```bash
   cd k8s
   ./deploy-poker.sh $PROJECT_ID $REGION us-central1-a
   ```

3. **Get service IPs**:
   ```bash
   kubectl get services -n poker-calculator
   ```

4. **Access the application**:
   - Frontend: http://<FRONTEND_IP>
   - Backend API: http://<BACKEND_IP>:8080

### Manual Deployment

For detailed step-by-step instructions, see:
- [DEPLOY_POKER.md](DEPLOY_POKER.md) - Poker calculator deployment guide
- [POKER_CALCULATOR.md](POKER_CALCULATOR.md) - Poker calculator documentation
- [k8s/README.md](k8s/README.md) - Comprehensive deployment guide
- [DEPLOY_TO_GCP.md](DEPLOY_TO_GCP.md) - GCP setup guide

### Deployment Scripts

- `k8s/deploy-poker.sh` - Full deployment automation
- `k8s/rebuild-frontend.sh` - Rebuild and push frontend image
- `k8s/update-frontend-api-poker.sh` - Update frontend API URL
- `k8s/get-poker-ips.sh` - Get service IP addresses
- `k8s/test-poker-api.sh` - Test API endpoints
- `k8s/verify-deployment.sh` - Verify deployment status

## 📁 Project Structure

```
distributed_systems/
├── backend/                    # Go gRPC backend
│   ├── main.go                # Main server code
│   ├── poker_server.go        # Poker service implementation
│   ├── poker.proto            # Poker gRPC service definition
│   ├── poker/                 # Poker evaluation logic
│   │   └── evaluator.go       # Hand evaluation and probability
│   ├── pb/                    # Generated protobuf code
│   ├── Dockerfile             # Backend container image
│   └── go.mod                 # Go dependencies
│
├── poker_calculator_flutter/  # Poker calculator Flutter frontend
│   ├── lib/
│   │   └── main.dart          # Main Flutter app
│   ├── web/                   # Web assets
│   ├── pubspec.yaml           # Flutter dependencies
│   └── Dockerfile             # Frontend container image
│
├── k8s/                       # Kubernetes manifests
│   ├── poker-backend-deployment.yaml
│   ├── poker-backend-service.yaml
│   ├── poker-backend-service-lb.yaml
│   ├── poker-frontend-deployment.yaml
│   ├── poker-frontend-service.yaml
│   ├── poker-namespace.yaml
│   ├── poker-frontend-configmap.yaml
│   ├── deploy-poker.sh        # Poker calculator deployment
│   ├── get-poker-ips.sh       # Get poker service IPs
│   ├── test-poker-api.sh      # Test poker API
│   ├── verify-deployment.sh   # Verify deployment
│   └── rebuild-frontend.sh    # Rebuild frontend
│
├── POKER_CALCULATOR.md        # Poker calculator documentation
├── DEPLOY_POKER.md            # Poker deployment guide
├── UI_TEST_EXAMPLES.md        # UI test examples
├── UI_BACKEND_CONNECTION.md   # Frontend-backend connection guide
├── RUN_POKER.md               # Local development guide
└── README.md                  # This file
```

## 🔧 Configuration

### Environment Variables

#### Backend
- `PORT`: Server port (default: 8080 for REST, 8081 for gRPC)

#### Frontend
- `API_URL`: Backend API URL (set during Docker build with `--dart-define=API_URL=...`)

## 🐛 Troubleshooting

### Common Issues

#### 1. Frontend JavaScript Errors
- **Solution**: Rebuild the frontend with the correct API URL
  ```bash
  cd k8s
  ./rebuild-frontend.sh pocker-486211 <BACKEND_IP>
  ```

#### 2. CORS Errors
- **Solution**: Backend includes CORS headers. Verify `Access-Control-Allow-Origin: *` is set
- See [FIX_CORS.md](FIX_CORS.md) for details

#### 3. GKE Authentication Issues
- **Solution**: Install `gke-gcloud-auth-plugin`
  ```bash
  gcloud components install gke-gcloud-auth-plugin
  ```
- See [FIX_GKE_AUTH.md](FIX_GKE_AUTH.md) for details

#### 4. Architecture Mismatch (exec format error)
- **Solution**: Build Docker images for `linux/amd64`:
  ```bash
  docker build --platform linux/amd64 -t image:tag .
  ```

#### 5. Pods Not Starting
- **Solution**: Check cluster resources and node capacity
  ```bash
  kubectl describe pod <pod-name> -n poker-calculator
  ```

#### 6. Invalid Hand Evaluation Results
- **Solution**: Ensure backend is rebuilt with latest code
  ```bash
  cd backend
  docker build --platform linux/amd64 -t gcr.io/PROJECT_ID/poker-calculator-backend:latest .
  docker push gcr.io/PROJECT_ID/poker-calculator-backend:latest
  kubectl rollout restart deployment/poker-calculator-backend -n poker-calculator
  ```

### Debugging Commands

```bash
# Check pod status
kubectl get pods -n poker-calculator

# View pod logs
kubectl logs <pod-name> -n poker-calculator

# Describe pod for events
kubectl describe pod <pod-name> -n poker-calculator

# Check services
kubectl get services -n poker-calculator

# Check deployments
kubectl get deployments -n poker-calculator

# Get service IPs
cd k8s
./get-poker-ips.sh
```

## 📚 Additional Documentation

- [POKER_CALCULATOR.md](POKER_CALCULATOR.md) - Poker calculator features and API
- [DEPLOY_POKER.md](DEPLOY_POKER.md) - Poker calculator deployment guide
- [UI_TEST_EXAMPLES.md](UI_TEST_EXAMPLES.md) - UI test examples and card values
- [UI_BACKEND_CONNECTION.md](UI_BACKEND_CONNECTION.md) - Frontend-backend connection guide
- [RUN_POKER.md](RUN_POKER.md) - Local development guide
- [k8s/README.md](k8s/README.md) - Detailed Kubernetes deployment guide
- [DEPLOY_TO_GCP.md](DEPLOY_TO_GCP.md) - GCP setup guide

## 🧪 Testing

### Backend Testing
```bash
cd backend
go test ./...
```

### API Testing with curl

```bash
# Evaluate Hand (Royal Flush)
curl -X POST http://localhost:8080/poker/evaluate-hand \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "SA"],
    "community_cards": ["DA", "CA", "HK", "HQ", "HJ"]
  }'

# Compare Hands
curl -X POST http://localhost:8080/poker/compare-hands \
  -H "Content-Type: application/json" \
  -d '{
    "player1_hole_cards": ["HA", "SA"],
    "player1_community_cards": ["DA", "CA", "HK", "HQ", "HJ"],
    "player2_hole_cards": ["HK", "HQ"],
    "player2_community_cards": ["DA", "CA", "HA", "SA", "HJ"]
  }'

# Calculate Probability
curl -X POST http://localhost:8080/poker/calculate-probability \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "SA"],
    "community_cards": [],
    "num_players": 4,
    "num_simulations": 10000
  }'
```

Or use the test script:
```bash
cd k8s
./test-poker-api.sh http://localhost:8080
```

## 🎮 Quick Access

### Local Development
- **Frontend**: Run `flutter run -d chrome` from `poker_calculator_flutter/`
- **Backend API**: http://localhost:8080/poker/*

### Deployed Services
- **Frontend**: http://34.31.107.248 (or check `kubectl get services -n poker-calculator`)
- **Backend API**: http://34.135.82.97:8080
- **Health Check**: http://34.135.82.97:8080/health

### Get Service IPs
```bash
cd k8s
./get-poker-ips.sh
```

## 🃏 Card Format

Cards are specified as 2-character strings:
- **Suit**: `H` (Hearts), `D` (Diamonds), `C` (Clubs), `S` (Spades)
- **Rank**: `2-9`, `T` (Ten), `J` (Jack), `Q` (Queen), `K` (King), `A` (Ace)

**Examples:**
- `HA` = Ace of Hearts
- `S7` = 7 of Spades
- `CT` = Ten of Clubs
- `DK` = King of Diamonds

## 🔒 Security Considerations

- CORS is configured to allow all origins (`*`) - restrict in production
- No authentication/authorization implemented - add for production use
- Health checks are exposed - consider restricting access
- Use HTTPS in production (see `k8s/managed-certificate.yaml`)

## 📝 License

This project is provided as-is for educational and demonstration purposes.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the additional documentation files
3. Check Kubernetes pod logs for errors
4. Verify Docker images are built for the correct platform

---

**Built with ❤️ using Go, Flutter, Docker, and Kubernetes**
