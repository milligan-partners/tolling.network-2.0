# Chaincode as a Service (ccaas) Dockerfile
# Copyright 2016-2026 Milligan Partners LLC
# SPDX-License-Identifier: Apache-2.0
#
# This Dockerfile builds the NIOP chaincode as an external gRPC server
# that peers connect to, rather than the traditional model where peers
# manage chaincode containers directly.
#
# Build from project root:
#   docker build -t niop-chaincode:1.0 -f chaincode/niop/ccaas/Dockerfile .
#
# Run:
#   docker run -e CHAINCODE_ID=<package_id> -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:9999 niop-chaincode:1.0

# Stage 1: Build the chaincode binary
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git

WORKDIR /src

# Copy entire chaincode directory to handle the replace directive
# The go.mod in niop has: replace ../shared
COPY chaincode/shared /src/chaincode/shared
COPY chaincode/niop /src/chaincode/niop

WORKDIR /src/chaincode/niop

# Download dependencies
RUN go mod download

# Build the chaincode binary with static linking for alpine
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s" \
    -o /chaincode-server \
    ./cmd

# Stage 2: Create minimal runtime image
FROM alpine:3.19

# Add ca-certificates for TLS if needed
RUN apk add --no-cache ca-certificates

# Create non-root user for security
RUN adduser -D -u 1000 chaincode
USER chaincode

WORKDIR /app

# Copy the built binary
COPY --from=builder /chaincode-server /app/chaincode-server

# Environment variables for chaincode server
# CHAINCODE_ID: The package ID assigned during install
# CHAINCODE_SERVER_ADDRESS: The address the chaincode server listens on
ENV CHAINCODE_ID=""
ENV CHAINCODE_SERVER_ADDRESS="0.0.0.0:9999"

# Expose the chaincode server port
EXPOSE 9999

# Run the chaincode server
ENTRYPOINT ["/app/chaincode-server"]
