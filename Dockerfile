# Build Stage
FROM golang:1.11.1-alpine AS builder

# Set environment variables for Go paths
ENV GOPATH /go
ENV APP_PATH $GOPATH/src/github.com/txst-sysops/prometheus-exporter-bigip

# Copy application source code into the build image
COPY . $APP_PATH

# Install build dependencies
RUN apk add --update -t build-deps go git mercurial libc-dev gcc libgcc

WORKDIR $APP_PATH

# main build
RUN go build -o /bigip_exporter

#RUN rm -rfv $APP_PATH

FROM golang:1.11.1-alpine AS final
 
# Copy the compiled binary from the builder stage
COPY --from=builder /bigip_exporter /bigip_exporter

# Expose the application port
EXPOSE 9142

# Set the entrypoint
ENTRYPOINT [ "/bigip_exporter" ]
CMD        [ "--config", "/config.yaml" ]

