# syntax=docker/dockerfile:1

# =============================================================================
# Build stage — compile the requested service binary.
# ARG SERVICE must be one of: api | worker
# =============================================================================
FROM golang:1.25-alpine AS builder

ARG SERVICE
RUN test -n "$SERVICE" || (echo "ARG SERVICE is required (api | worker)" && exit 1)

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -o /bin/app \
    ./cmd/${SERVICE}

# =============================================================================
# Runtime stage
# =============================================================================
FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata wget

RUN addgroup -S app && adduser -S app -G app

COPY --from=builder /bin/app /usr/local/bin/app

USER app

ENTRYPOINT ["app"]
