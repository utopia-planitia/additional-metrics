FROM docker.io/library/golang:1.23.4-alpine@sha256:9a31ef0803e6afdf564edc8ba4b4e17caed22a0b1ecd2c55e3c8fdd8d8f68f98 AS workbench

WORKDIR /src

# dependencies
COPY go.mod /src
COPY go.sum /src
ENV GOCACHE=/root/.cache/go-build CGO_ENABLED=0
RUN --mount=type=cache,target="/root/.cache/go-build" go mod download

# binary
COPY . /src
RUN --mount=type=cache,target="/root/.cache/go-build" go build -o /bin/metrics ./main.go

FROM docker.io/library/alpine:3.20.3@sha256:1e42bbe2508154c9126d48c2b8a75420c3544343bf86fd041fb7527e017a4b4a

ENV IPTABLES_VERSION=1.8.9
RUN set -eux; \
    apk upgrade --no-cache; \
    apk add --no-cache \
        bash \
        coreutils \
        gawk \
        iptables="~${IPTABLES_VERSION:?}" \
        ; \
    # smoke tests
    awk --version; \
    bash --version; \
    iptables-save --version | tee -a /dev/stderr | grep -Fq "${IPTABLES_VERSION:?}"; \
    sort --version; \
    tail --version; \
    uniq --version
        
COPY /iptables-wrapper-installer.sh /iptables-wrapper-installer.sh
RUN /iptables-wrapper-installer.sh --no-sanity-check

WORKDIR /bin
COPY --from=workbench /bin/metrics /bin/metrics
COPY iptables-metric.sh /bin/iptables-metric.sh
CMD ["/bin/metrics"]
