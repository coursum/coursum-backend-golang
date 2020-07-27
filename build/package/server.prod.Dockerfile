ARG GO_VERSION

FROM golang:${GO_VERSION} AS builder

RUN apk --no-cache add tzdata
WORKDIR /go/src/app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /go/bin/app ./cmd/server/main.go



FROM scratch AS final

COPY --from=builder /go/bin/app /go/bin/app
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

ENTRYPOINT ["/go/bin/app"]
