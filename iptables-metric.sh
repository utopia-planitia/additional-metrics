#!bash

set -euxo pipefail

iptables-save | sort | uniq -c | sort | tail -n 1 | awk '{ print $1 }'
