# Build Stage
FROM golang:1.20-alpine AS builder

# Set environment variables for Go paths
ENV GOPATH /go
ENV APPPATH $GOPATH/src/bigip_exporter

# Install build dependencies
RUN apk add --no-cache git mercurial

# Set up the application directory
WORKDIR $APPPATH

# Copy application source code into the build image
COPY . .

# Install govendor and build the application
RUN go install github.com/kardianos/govendor@latest && \
    $GOPATH/bin/govendor build +p

# Final Stage
FROM alpine:latest

# Expose the application port
EXPOSE 9142

# Copy the compiled binary from the builder stage
COPY --from=builder /go/src/bigip_exporter/bigip_exporter /bigip_exporter

# Set the entrypoint
ENTRYPOINT ["/bigip_exporter"]

