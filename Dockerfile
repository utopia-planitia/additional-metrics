FROM docker.io/library/golang:1.23.12-alpine@sha256:383395b794dffa5b53012a212365d40c8e37109a626ca30d6151c8348d380b5f AS workbench

WORKDIR /src

# dependencies
COPY go.mod /src
COPY go.sum /src
ENV GOCACHE=/root/.cache/go-build CGO_ENABLED=0
RUN --mount=type=cache,target="/root/.cache/go-build" go mod download

# binary
COPY . /src
RUN --mount=type=cache,target="/root/.cache/go-build" go build -o /bin/metrics ./main.go

FROM docker.io/library/alpine:3.18.12@sha256:de0eb0b3f2a47ba1eb89389859a9bd88b28e82f5826b6969ad604979713c2d4f

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
