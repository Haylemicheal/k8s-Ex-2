# Build stage
FROM golang:latest AS builder

# Install protoc and protoc plugins
RUN apt-get update && apt-get install -y protobuf-compiler git && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest

# Add GOPATH/bin to PATH
ENV PATH=$PATH:/go/bin

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Get googleapis for proto annotations
RUN git clone --depth 1 https://github.com/googleapis/googleapis /tmp/googleapis || true

# Copy proto files
COPY temperature.proto ./
COPY poker.proto ./

# Generate gRPC code for temperature
RUN mkdir -p pb && \
    protoc --go_out=. --go_opt=paths=source_relative \
           --go-grpc_out=. --go-grpc_opt=paths=source_relative \
           temperature.proto && \
    mv temperature.pb.go pb/ && \
    mv temperature_grpc.pb.go pb/

# Generate gRPC code for poker
RUN protoc --go_out=. --go_opt=paths=source_relative \
           --go-grpc_out=. --go-grpc_opt=paths=source_relative \
           poker.proto && \
    mv poker.pb.go pb/ && \
    mv poker_grpc.pb.go pb/

# Copy source code
COPY main.go ./
COPY poker_server.go ./
COPY poker/ ./poker/

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o temperature-converter main.go poker_server.go

# Final stage
FROM alpine:latest

# Install ca-certificates and wget for healthcheck
RUN apk --no-cache add ca-certificates wget

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/temperature-converter .

# Expose port 8080
EXPOSE 8080

# Run the application
CMD ["./temperature-converter"]

