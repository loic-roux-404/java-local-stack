#!/usr/bin/env bash

set -eo pipefail

echo "Checking if port $1 is open ..."
if timeout $2 sh -c "while ! ss -tnl src :$1 | grep -q -w \"$1\"; do sleep 1; done"; then \
    exit 0; \
else \
    echo "Port $1 is not open! Service might be down or unhealthy."; \
    exit 1; \
fi
