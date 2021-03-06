# We use a multistage build to avoid bloating our deployment image with build dependencies
FROM golang:1.9.0-alpine3.6 as builder
MAINTAINER Monax <support@monax.io>

ARG REPO=$GOPATH/src/github.com/monax/hoard
COPY . $REPO
WORKDIR $REPO

# Build purely static binaries
RUN go build --ldflags '-extldflags "-static"' -o bin/hoard ./cmd/hoard
RUN go build --ldflags '-extldflags "-static"' -o bin/hoarctl ./cmd/hoarctl

#
# N.B. Actual runtime container definitions starts here!
#
# This will be our base container image
FROM alpine:3.6

# We like it when TLS works
RUN apk add --no-cache ca-certificates

ARG REPO=/go/src/github.com/monax/hoard

# Copy binaries built in previous stage
COPY --from=builder $REPO/bin/* /usr/local/bin/

EXPOSE 53431

ENV HOARD_JSON_CONFIG '{"ListenAddress":"tcp://:53431","Storage":{"StorageType":"memory","AddressEncoding":"base64"},"Logging":{"LoggingType":"logfmt","Channels":["info","trace"]}}'

CMD [ "hoard", "-e", "-l" ]
