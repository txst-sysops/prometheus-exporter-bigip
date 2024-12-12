# Build Stage
FROM golang:1.11.1-alpine AS builder

# Set environment variables for Go paths
ENV GOPATH /go
ENV APPPATH $GOPATH/src/github.com/txst-sysops/prometheus-exporter-bigip

# Copy application source code into the build image
COPY . $APPPATH

# Install build dependencies
RUN apk add --update -t build-deps go git mercurial libc-dev gcc libgcc

WORKDIR $APPPATH

# main build
RUN go build -o /bigip_exporter

# Expose the application port
EXPOSE 9142

# Set the entrypoint
ENTRYPOINT ["/bigip_exporter"]

