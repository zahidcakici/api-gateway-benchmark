## express-gateway Detailed Results

### Performance Metrics
- **Requests/sec:** 6297.09
- **Mean Latency:** 32.05ms
- **Min Latency:** 15.34ms
- **Max Latency:** 1.06s
- **50th Percentile:** 31.20ms
- **90th Percentile:** 36.51ms
- **99th Percentile:** 43.25ms
- **99.9th Percentile:** N/A
- **Average CPU:** 106.25%
- **Average Memory:** 141.9 MB
- **Round-Robin Status:** ✓

### Raw wrk Output
```
Running 1m test @ http://localhost:8000/
  4 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    32.05ms   15.34ms   1.06s    98.40%
    Req/Sec     1.58k   158.96     1.98k    70.54%
  Latency Distribution
     50%   31.20ms
     75%   34.21ms
     90%   36.51ms
     99%   43.25ms
  378341 requests in 1.00m, 59.17MB read
  Socket errors: connect 0, read 64, write 0, timeout 0
Requests/sec:   6297.09
Transfer/sec:      0.98MB
```
