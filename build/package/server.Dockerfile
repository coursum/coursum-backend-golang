ARG GO_VERSION

FROM golang:${GO_VERSION}

WORKDIR /workdir

ENTRYPOINT ["go", "run", "cmd/server/main.go"]
