# API Gateway Benchmark Suite

A comprehensive benchmarking suite for comparing API Gateway performance on MacBook Pro M1 Pro (8 cores).

## Overview

This benchmark suite tests the following API Gateways:
- **Express Gateway** - Node.js-based gateway
- **Ocelot** - .NET Core gateway  
- **Kong** - Lua-based gateway
- **KrakenD** - Go-based high-performance gateway
- **Tyk** - Go-based gateway with Redis
- **Apache APISIX** - Lua-based gateway
- **Nginx** - Traditional reverse proxy

## Features

✅ **Isolated Testing**: Each gateway runs independently to avoid interference  
✅ **Round-Robin Load Balancing**: All gateways configured for proper load distribution  
✅ **No Caching**: All gateways configured to disable caching  
✅ **Resource Monitoring**: CPU and memory usage tracking  
✅ **M1 Pro Optimized**: Settings optimized for 8-core Apple Silicon  

## Prerequisites

### Required Software
```bash
# Install wrk (HTTP benchmarking tool)
brew install wrk

# Install Docker Desktop for Mac
# Download from: https://www.docker.com/products/docker-desktop/

# Verify installations
wrk --version
docker --version
docker-compose --version
```

### Backend Services
The benchmark uses 5 identical Go backend services (`app1-app5`) that return "Hello World from {app_name}".

## Configuration Review

### ✅ Round-Robin Verification

| Gateway | Configuration | Status |
|---------|---------------|--------|
| Express Gateway | `strategy: round-robin` | ✅ |
| Kong | `algorithm: round-robin` | ✅ |
| KrakenD | Default behavior | ✅ |
| Nginx | Default behavior | ✅ |
| APISIX | `type: roundrobin` | ✅ |
| Ocelot | `"Type": "RoundRobin"` | ✅ |
| Tyk | `"type": "round_robin"` | ✅ |

### ✅ Caching Configuration

| Gateway | Configuration | Status |
|---------|---------------|--------|
| Express Gateway | No caching by default | ✅ |
| Kong | No caching configured | ✅ |
| KrakenD | `"cache_ttl": "0s"` | ✅ |
| Nginx | No caching configured | ✅ |
| APISIX | No caching configured | ✅ |
| Ocelot | No caching configured | ✅ |
| Tyk | `"disable_cache": true` | ✅ |

## Benchmark Scripts

### 1. Isolated Benchmark (Recommended)
**File**: `isolated-benchmark.sh`

Runs each gateway independently for unbiased comparison.

```bash
./isolated-benchmark.sh
```

**Features**:
- Tests one gateway at a time
- Stops containers between tests
- All gateways use port 8000
- Validates round-robin behavior
- Optimized for M1 Pro (8 cores, 200 connections, 8 threads)

### 2. Comprehensive Benchmark
**File**: `comprehensive-benchmark.sh`

Runs all gateways simultaneously (may have resource contention).

```bash
./comprehensive-benchmark.sh
```

### 3. Round-Robin Validation
**File**: `validate-round-robin-simple.sh`

Validates that a running gateway properly distributes requests.

```bash
# Start a gateway first
docker-compose up -d app1 app2 app3 app4 app5 express-gateway

# Then test round-robin
./validate-round-robin-simple.sh
```

### 4. Resource Monitoring
**File**: `monitor-resources-detailed.sh`

Detailed resource monitoring for a specific container.

```bash
# Monitor express-gateway for 60 seconds
./monitor-resources-detailed.sh express-gateway 60
```

## Test Parameters (M1 Pro Optimized)

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| **Connections** | 200 | Good balance for M1 Pro without overwhelming |
| **Threads** | 8 | Matches 8 CPU cores |
| **Duration** | 60s | Long enough for stable measurements |
| **Warmup** | 15s | Ensures JIT compilation and stabilization |

## Running the Benchmark

### Quick Start
```bash
# Clone and navigate to the project
cd api-gateway-benchmark

# Run the isolated benchmark (recommended)
./isolated-benchmark.sh
```

### Manual Testing
```bash
# Start backend services
docker-compose up -d app1 app2 app3 app4 app5

# Test a specific gateway (e.g., Express Gateway)
docker-compose up -d express-gateway

# Validate it's working
curl http://localhost:8000/

# Run a quick test
wrk -t8 -c200 -d30s http://localhost:8000/

# Stop the gateway
docker-compose stop express-gateway
```

## Results Interpretation

### Performance Metrics
- **RPS**: Requests per second (higher is better)
- **Latency**: Response time (lower is better)
- **P50/P90/P99**: Percentile latencies (lower is better)
- **CPU %**: Average CPU usage during test
- **Memory %**: Average memory usage during test

### Expected Results Order (Typical)
1. **Nginx** - Highest RPS, lowest latency
2. **KrakenD** - High performance Go implementation
3. **APISIX** - Fast Lua-based gateway
4. **Kong** - Established Lua-based gateway
5. **Tyk** - Go-based with Redis overhead
6. **Express Gateway** - Node.js based
7. **Ocelot** - .NET Core based

*Note: Actual results may vary based on system configuration and current load.*

## File Structure

```
api-gateway-benchmark/
├── isolated-benchmark.sh           # Main isolated benchmark script
├── comprehensive-benchmark.sh      # Concurrent benchmark script  
├── validate-round-robin-simple.sh  # Round-robin validation
├── monitor-resources-detailed.sh   # Detailed resource monitoring
├── monitor-resources.sh           # Simple resource monitoring
├── docker-compose.yaml            # All services configuration
├── app/                           # Go backend application
│   ├── Dockerfile
│   ├── main.go
│   ├── go.mod
│   └── go.sum
└── gateways/                      # Gateway configurations
    ├── express-gateway/
    │   └── gateway.config.yml
    ├── kong/
    │   └── kong.yaml
    ├── krakend/
    │   └── krakend.json
    ├── nginx/
    │   └── nginx.conf
    ├── apisix/
    │   └── apisix.yaml
    ├── ocelot/
    │   ├── Dockerfile
    │   ├── Program.cs
    │   └── ocelot.json
    └── tyk/
        └── tyk.conf
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Kill processes using port 8000
   lsof -ti:8000 | xargs kill -9
   ```

2. **Docker Issues**
   ```bash
   # Clean up containers
   docker-compose down
   docker system prune
   ```

3. **Gateway Not Responding**
   ```bash
   # Check container logs
   docker logs express-gateway
   ```

4. **Round-Robin Not Working**
   - Check gateway configuration files
   - Ensure all backend services are running
   - Validate with `validate-round-robin-simple.sh`

### Performance Tips

1. **Close Unnecessary Applications**: Free up CPU and memory
2. **Disable Spotlight Indexing**: Temporarily for consistent results
3. **Use Activity Monitor**: Monitor system resources during tests
4. **Run Multiple Times**: Average results across multiple runs

## Contributing

To add a new gateway:

1. Create configuration file in `gateways/{gateway-name}/`
2. Add service to `docker-compose.yaml` 
3. Configure round-robin load balancing
4. Disable caching
5. Add to gateway list in benchmark scripts

## License

MIT License - Feel free to modify and distribute.

---

**Happy Benchmarking! 🚀**
