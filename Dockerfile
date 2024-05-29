FROM docker.io/library/golang:1.22.3-alpine@sha256:421bc7f4b90d042c56282bb894451108f8ab886687e1b73abaefad31ab10a14d AS workbench

WORKDIR /src

# dependencies
COPY go.mod /src
COPY go.sum /src
ENV GOCACHE=/root/.cache/go-build CGO_ENABLED=0
RUN --mount=type=cache,target="/root/.cache/go-build" go mod download

# binary
COPY . /src
RUN --mount=type=cache,target="/root/.cache/go-build" go build -o /bin/metrics ./main.go

FROM docker.io/library/alpine:3.18.6@sha256:11e21d7b981a59554b3f822c49f6e9f57b6068bb74f49c4cd5cc4c663c7e5160

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
