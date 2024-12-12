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

# Install govendor and build the application
RUN go get -u github.com/kardianos/govendor

# main build
RUN go build -o /bigip_exporter
#RUN $GOPATH/bin/govendor build +p

# Final Stage
#FROM alpine:latest

# Expose the application port
EXPOSE 9142

# Copy the compiled binary from the builder stage
RUN echo -n PWD: && pwd
RUN ls -l /
#RUN cp bigip_exporter /bigip_exporter
#COPY --from=builder $APPPATH/bigip_exporter /bigip_exporter

RUN 

# Set the entrypoint
ENTRYPOINT ["/bigip_exporter"]

