FROM golang:1.21 AS builder
WORKDIR /go/src/cluster-compare/collector-addon
COPY . .
RUN ls -al 

RUN ls -al /
ENV GO_PACKAGE /cluster-compare/collector-addon

# Build
RUN make build --warn-undefined-variables

RUN ls -al /go/src/cluster-compare/collector-addon/bin/cluster-compare-collector-addon

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /go/src/cluster-compare/collector-addon/bin/cluster-compare-collector-addon /

RUN ls -al 

ENTRYPOINT ["/cluster-compare-collector-addon"]
