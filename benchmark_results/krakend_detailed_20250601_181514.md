## krakend Detailed Results

### Performance Metrics
- **Requests/sec:** 23636.76
- **Mean Latency:** 55.87ms
- **Min Latency:** 91.73ms
- **Max Latency:** 1.40s
- **50th Percentile:** 4.35ms
- **90th Percentile:** 171.14ms
- **99th Percentile:** 475.37ms
- **99.9th Percentile:** N/A
- **Average CPU:** 220.76%
- **Average Memory:** 99.0 MB
- **Round-Robin Status:** ✓

### Raw wrk Output
```
Running 1m test @ http://localhost:8000/
  4 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    55.87ms   91.73ms   1.40s    85.26%
    Req/Sec     5.94k     1.21k   11.33k    71.83%
  Latency Distribution
     50%    4.35ms
     75%   94.16ms
     90%  171.14ms
     99%  475.37ms
  1418747 requests in 1.00m, 263.84MB read
  Socket errors: connect 0, read 67, write 0, timeout 0
Requests/sec:  23636.76
Transfer/sec:      4.40MB
```
