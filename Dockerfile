FROM golang:1.24-alpine AS builder

ARG MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z

RUN apk add --no-cache \
    git \
    ca-certificates \
    build-base

WORKDIR /src

RUN git clone https://github.com/minio/minio.git . \
    && git checkout ${MINIO_VERSION}

RUN CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    go build \
    -trimpath \
    -ldflags "-s -w -X github.com/minio/minio/cmd.Version=${MINIO_VERSION}" \
    -o /minio


FROM alpine:3.22

RUN apk add --no-cache \
    ca-certificates \
    curl

RUN addgroup -S minio \
    && adduser -S -G minio minio \
    && mkdir -p /data \
    && chown -R minio:minio /data

COPY --from=builder /minio /usr/bin/minio

USER minio

VOLUME ["/data"]

EXPOSE 9000 9001

ENTRYPOINT ["/usr/bin/minio"]

CMD ["server", "/data", "--console-address", ":9001"]