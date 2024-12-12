# Build Stage
FROM golang:1.11.1-alpine AS builder

# Set environment variables for Go paths
ENV GO_PATH /go
ENV APP_PATH $GO_PATH/src/github.com/txst-sysops/prometheus-exporter-bigip

# Install build dependencies
RUN apk add --update -t build-deps go git mercurial libc-dev gcc libgcc

# Copy application source code into the build image
COPY . $APP_PATH

WORKDIR $APP_PATH

# Install govendor and build the application
RUN go get -u github.com/kardianos/govendor

# main build
RUN $GO_PATH/bin/govendor build +p

# Final Stage
FROM alpine:latest

# Expose the application port
EXPOSE 9142

# Copy the compiled binary from the builder stage
RUN cp bigip_exporter /bigip_exporter
#COPY --from=builder $APP_PATH/bigip_exporter /bigip_exporter

RUN 

# Set the entrypoint
ENTRYPOINT ["/bigip_exporter"]

