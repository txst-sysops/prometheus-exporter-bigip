# Build Stage
FROM golang:1.20-alpine AS builder

# Set environment variables for Go paths
ENV GO_PATH /go
ENV APP_PATH $GO_PATH/src/github.com/txst-sysops/prometheus-exporter-bigip

# Install build dependencies
RUN apk add --update -t build-deps go git mercurial libc-dev gcc libgcc

# Copy application source code into the build image
COPY . $APP_PATH

WORKDIR $APP_PATH

# Install govendor and build the application
RUN go install github.com/kardianos/govendor@latest
RUN ls -l /go/src/github.com/txst-sysops/ /go/src/github.com/txst-sysops/*/

# main build
RUN $GO_PATH/bin/govendor build +p

# Final Stage
FROM alpine:latest

# Expose the application port
EXPOSE 9142

# Copy the compiled binary from the builder stage
COPY --from=builder $APP_PATH/bigip_exporter /bigip_exporter

RUN 

# Set the entrypoint
ENTRYPOINT ["/bigip_exporter"]

