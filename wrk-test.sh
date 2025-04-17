#!/bin/sh

GATEWAYS=("express-gateway")
DURATION=60s
CONNECTIONS=100
THREADS=4

echo "Running benchmarks with $CONNECTIONS connections and $THREADS threads for $DURATION"

for gateway in "${GATEWAYS[@]}"
do
    echo "Testing $gateway..."
    wrk -t$THREADS -c$CONNECTIONS -d$DURATION --latency http://localhost:8083/
    echo "-------------------------------------------------------"
done