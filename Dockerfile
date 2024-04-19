FROM golang:1.22.2-alpine AS workbench

WORKDIR /src
COPY . /src

ENV GOCACHE=/root/.cache/go-build
RUN --mount=type=cache,target="/root/.cache/go-build" go build -o /bin/metrics ./main.go

FROM alpine:3.18

RUN apk --update --no-cache add iptables coreutils gawk bash

COPY /iptables-wrapper-installer.sh /iptables-wrapper-installer.sh
RUN /iptables-wrapper-installer.sh --no-sanity-check

RUN iptables-save --version
RUN sort --version
RUN uniq --version
RUN tail --version
RUN awk --version
RUN bash --version

WORKDIR /bin
COPY --from=workbench /bin/metrics /bin/metrics
COPY iptables-metric.sh /bin/iptables-metric.sh
CMD ["/bin/metrics"]
