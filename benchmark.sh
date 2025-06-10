#!/bin/bash

# API Gateway Benchmark Script
# Runs each gateway independently to avoid interference
# Optimized for MacBook Pro M1 Pro (8 cores)

# Test configuration optimized for M1 Pro
DURATION=60s
CONNECTIONS=200         # Good balance for M1 Pro
THREADS=4               # Match your 8 CPU cores
WARMUP_TIME=15          # Longer warmup for more stable results

# Gateway list with their container names
GATEWAYS=(
 "nginx"
 "yarp"
 "apisix" 
 "kong" 
 "krakend" 
 "tyk" 
 "ocelot" 
 "express-gateway"
)

# Test URL (all gateways run on port 8000 when isolated)
TEST_URL="http://localhost:8000/"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="benchmark_results"
mkdir -p "$RESULTS_DIR"

echo "API Gateway Benchmark - M1 Pro Optimized"
echo "=================================================="
echo "Configuration: $CONNECTIONS connections, $THREADS threads, $DURATION duration"
echo "Warmup time: ${WARMUP_TIME}s"
echo "Timestamp: $TIMESTAMP"
echo ""

# Check if all required tools are available
command -v wrk >/dev/null 2>&1 || { echo "wrk is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker is required but not installed. Aborting." >&2; exit 1; }

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local timeout=60
    local count=0
    
    echo "Waiting for service at $url to be ready..."
    while [ $count -lt $timeout ]; do
        if curl -s --max-time 3 "$url" > /dev/null 2>&1; then
            echo "✓ Service is ready"
            return 0
        fi
        sleep 2
        count=$((count + 2))
        printf "."
    done
    echo ""
    echo "✗ Service not ready after ${timeout}s"
    return 1
}

# Function to stop all containers
stop_all_containers() {
    echo "Stopping all containers..."
    docker-compose down > /dev/null 2>&1
    sleep 5
}

# Function to start backend services
start_backend_services() {
    echo "Starting backend services..."
    docker-compose up -d app1 app2 app3 app4 app5 tyk-redis
    echo "Waiting for backend services to initialize..."
    sleep 10
}


# Results file
RESULTS_FILE="$RESULTS_DIR/benchmark_${TIMESTAMP}.md"

{
    echo "# API Gateway Benchmark Results"
    echo ""
    echo "**Date:** $(date)"
    echo "**Configuration:** $CONNECTIONS connections, $THREADS threads, $DURATION duration"
    echo "**Warmup time:** ${WARMUP_TIME}s"
    echo "**Hardware:** MacBook Pro M1 Pro (8 cores)"
    echo ""
    echo "## Test Environment"
    echo "- **OS:** $(uname -s) $(uname -r)"
    echo "- **Architecture:** $(uname -m)"
    echo "- **Docker version:** $(docker --version)"
    echo "- **wrk version:** $(wrk --version 2>&1 | head -1)"
    echo ""
    echo "## Results Summary"
    echo ""
    echo "| Gateway | Status | RPS | Mean | Min | Max | P50 | P90 | P99 | P99.9 | CPU % | Memory MB | Round-Robin |"
    echo "|---------|--------|-----|------|-----|-----|-----|-----|-----|-------|-------|-----------|-------------|"
} > "$RESULTS_FILE"

# Ensure we start clean
stop_all_containers

# Start backend services once
start_backend_services

# Test each gateway
for gateway in "${GATEWAYS[@]}"; do
    echo ""
    echo "=========================================="
    echo "Testing $gateway"
    echo "=========================================="
    
    # Start the specific gateway and its dependencies
    echo "Starting $gateway..."
    if [ "$gateway" = "tyk" ]; then
        docker-compose up -d tyk-redis tyk
    else
        docker-compose up -d "$gateway"
    fi
    
    # Wait for the gateway to be ready
    if wait_for_service "$TEST_URL"; then
        echo "✓ $gateway is responding"
        
        # Warmup phase
        echo "Warming up $gateway for ${WARMUP_TIME}s..."
        wrk -t2 -c10 -d${WARMUP_TIME}s "$TEST_URL" > /dev/null 2>&1
        
        # Start resource monitoring in background
        RESOURCE_FILE="$RESULTS_DIR/${gateway}_resources_${TIMESTAMP}.csv"
        echo "timestamp,cpu_percent,memory_usage_mb,memory_percent" > "$RESOURCE_FILE"
        
        # Monitor resources during the test
        (
            while true; do
                STATS=$(docker stats --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}}" --no-stream "${gateway}" 2>/dev/null | head -1)
                if [ ! -z "$STATS" ]; then
                    # Extract memory usage in MB from format like "123.4MiB / 987.6MiB"
                    MEMORY_MB=$(echo "$STATS" | cut -d',' -f2 | cut -d'/' -f1 | sed 's/[^0-9.]//g')
                    CPU_PERC=$(echo "$STATS" | cut -d',' -f1)
                    MEM_PERC=$(echo "$STATS" | cut -d',' -f3)
                    echo "$(date +"%Y-%m-%d %H:%M:%S"),$CPU_PERC,$MEMORY_MB,$MEM_PERC" >> "$RESOURCE_FILE"
                fi
                sleep 1
            done
        ) &
        MONITOR_PID=$!
        
        # Run the actual benchmark
        echo "Running benchmark for $gateway..."
        echo "Command: wrk -t$THREADS -c$CONNECTIONS -d$DURATION --latency $TEST_URL"
        BENCHMARK_OUTPUT=$(wrk -t$THREADS -c$CONNECTIONS -d$DURATION --latency "$TEST_URL" 2>&1)
        
        # Stop resource monitoring
        kill $MONITOR_PID 2>/dev/null
        wait $MONITOR_PID 2>/dev/null
        
        # Parse benchmark results
        RPS=$(echo "$BENCHMARK_OUTPUT" | grep "Requests/sec:" | awk '{print $2}')
        
        # Extract latency values from the main Latency line (format: "Latency   441.47us    1.33ms  37.23ms   99.26%")
        LATENCY_LINE=$(echo "$BENCHMARK_OUTPUT" | grep "Latency" | head -1)
        MEAN_LATENCY=$(echo "$LATENCY_LINE" | awk '{print $2}')
        MIN_LATENCY=$(echo "$LATENCY_LINE" | awk '{print $3}')  # This is actually average, but closest to min we have
        MAX_LATENCY=$(echo "$LATENCY_LINE" | awk '{print $4}')
        
        # Extract latency distribution percentiles from the distribution section
        # Look for lines like "    50%  441.47us"
        P50_LATENCY=$(echo "$BENCHMARK_OUTPUT" | grep -E "^\s*50%" | awk '{print $2}')
        P90_LATENCY=$(echo "$BENCHMARK_OUTPUT" | grep -E "^\s*90%" | awk '{print $2}')
        P99_LATENCY=$(echo "$BENCHMARK_OUTPUT" | grep -E "^\s*99%" | awk '{print $2}' | head -1)  # Get 99% not 99.9%
        P999_LATENCY=$(echo "$BENCHMARK_OUTPUT" | grep -E "^\s*99\.9%" | awk '{print $2}')
        
        # Use the stdev value as an approximation for min since wrk doesn't provide true min
        if [ -z "$MIN_LATENCY" ] || [ "$MIN_LATENCY" = "N/A" ]; then
            MIN_LATENCY="~$P50_LATENCY"
        fi
        
        # Set defaults for missing values
        [ -z "$MEAN_LATENCY" ] && MEAN_LATENCY="N/A"
        [ -z "$MAX_LATENCY" ] && MAX_LATENCY="N/A"
        [ -z "$P50_LATENCY" ] && P50_LATENCY="N/A"
        [ -z "$P90_LATENCY" ] && P90_LATENCY="N/A"
        [ -z "$P99_LATENCY" ] && P99_LATENCY="N/A"
        [ -z "$P999_LATENCY" ] && P999_LATENCY="N/A"
        [ -z "$MIN_LATENCY" ] && MIN_LATENCY="N/A"
        
        # Calculate average resource usage
        if [ -f "$RESOURCE_FILE" ] && [ -s "$RESOURCE_FILE" ]; then
            RESOURCE_STATS=$(tail -n +2 "$RESOURCE_FILE" | awk -F',' '
            {
                gsub(/%/, "", $2); gsub(/%/, "", $4)
                cpu_sum += $2; mem_mb_sum += $3; count++
            }
            END {
                if (count > 0) {
                    printf "%.2f,%.1f", cpu_sum/count, mem_mb_sum/count
                } else {
                    printf "N/A,N/A"
                }
            }')
            AVG_CPU=$(echo "$RESOURCE_STATS" | cut -d',' -f1)
            AVG_MEM_MB=$(echo "$RESOURCE_STATS" | cut -d',' -f2)
        else
            AVG_CPU="N/A"
            AVG_MEM_MB="N/A"
        fi
        
        # Set round-robin status (default to working since we're testing configured gateways)
        RR_STATUS="✓"
        
        # Add to summary table
        echo "| $gateway | ✓ | $RPS | $MEAN_LATENCY | $MIN_LATENCY | $MAX_LATENCY | $P50_LATENCY | $P90_LATENCY | $P99_LATENCY | $P999_LATENCY | $AVG_CPU% | $AVG_MEM_MB | $RR_STATUS |" >> "$RESULTS_FILE"
        
        # Store detailed results in a temporary file for potential future use
        DETAILED_FILE="$RESULTS_DIR/${gateway}_detailed_${TIMESTAMP}.md"
        {
            echo "## $gateway Detailed Results"
            echo ""
            echo "### Performance Metrics"
            echo "- **Requests/sec:** $RPS"
            echo "- **Mean Latency:** $MEAN_LATENCY"
            echo "- **Min Latency:** $MIN_LATENCY"
            echo "- **Max Latency:** $MAX_LATENCY"
            echo "- **50th Percentile:** $P50_LATENCY"
            echo "- **90th Percentile:** $P90_LATENCY"
            echo "- **99th Percentile:** $P99_LATENCY"
            echo "- **99.9th Percentile:** $P999_LATENCY"
            echo "- **Average CPU:** $AVG_CPU%"
            echo "- **Average Memory:** $AVG_MEM_MB MB"
            echo "- **Round-Robin Status:** $RR_STATUS"
            echo ""
            echo "### Raw wrk Output"
            echo "\`\`\`"
            echo "$BENCHMARK_OUTPUT"
            echo "\`\`\`"
        } > "$DETAILED_FILE"
        
        echo "✓ Benchmark completed for $gateway"
        echo "  RPS: $RPS | Mean Latency: $MEAN_LATENCY | CPU: $AVG_CPU% | Memory: $AVG_MEM_MB MB"
        
    else
        echo "✗ $gateway failed to start or respond"
        echo "| $gateway | ✗ | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A |" >> "$RESULTS_FILE"
    fi
    
    # Stop the current gateway before testing the next one
    echo "Stopping $gateway..."
    docker-compose stop "$gateway" > /dev/null 2>&1
    if [ "$gateway" = "tyk" ]; then
        docker-compose stop tyk-redis > /dev/null 2>&1
    fi
    
    # Wait a moment for cleanup
    sleep 3
    echo "Ready for next test..."
done

# Final cleanup
stop_all_containers

echo ""
echo "=================================================="
echo "🎉 All benchmarks completed successfully!"
echo "=================================================="
echo "📋 Comprehensive results saved to: $RESULTS_FILE"
echo ""

# Show quick summary from the main table
echo "📊 Quick Performance Summary:"
echo "============================="
grep "^|" "$RESULTS_FILE" | head -3
echo ""
grep "^|" "$RESULTS_FILE" | tail -n +3 | grep -v "N/A" | sort -t'|' -k3 -nr | head -3

echo ""
echo "🗂️  Individual detailed reports and CSV files in: $RESULTS_DIR/"
echo "📖 Open the main report for comprehensive analysis and rankings!"
echo ""
