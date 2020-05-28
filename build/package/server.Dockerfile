ARG GO_VERSION

FROM golang:${GO_VERSION} AS builder

WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /go/bin/app ./cmd/server/main.go



FROM scratch

COPY --from=builder /go/bin/app /go/bin/app

ENTRYPOINT ["/go/bin/app"]
