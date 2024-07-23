FROM docker.io/library/golang:1.22.5-alpine@sha256:24f1bfa32fbf21eec3d764ed190adb78ee3147c6c3558c950c2be6bf6fc23a1b AS workbench

WORKDIR /src

# dependencies
COPY go.mod /src
COPY go.sum /src
ENV GOCACHE=/root/.cache/go-build CGO_ENABLED=0
RUN --mount=type=cache,target="/root/.cache/go-build" go mod download

# binary
COPY . /src
RUN --mount=type=cache,target="/root/.cache/go-build" go build -o /bin/metrics ./main.go

FROM docker.io/library/alpine:3.18.7@sha256:1875c923b73448b558132e7d4a44b815d078779ed7a73f76209c6372de95ea8d

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
