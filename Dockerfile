FROM golang:alpine AS builder
# Step 1: Build the Go application

# Set the working directory inside the container
WORKDIR /app

# Copy the Go modules manifests
COPY go.mod ./

# Download the Go modules
RUN go mod download

# Copy the source code
COPY . .

# Build the Go application
RUN go build -o server .

# Step 2: Create the final image
FROM alpine:latest

# Set the working directory inside the container
WORKDIR /root/

# Copy the compiled binary from the builder stage
COPY --from=builder /app/server .

# Expose the port the server will run on
EXPOSE 8080

# Command to run the application
CMD ["./server"]