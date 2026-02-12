# etcd Performance Tuning Recommendations

This document contains recommended `etcd` settings to use as a **workaround** for performance issues, specifically when `etcd` is running on slow disks or in an environment with high I/O contention.

## Context

The `etcd` database is extremely sensitive to latency. If disk I/O is slow, `etcd` can fail to meet its timing requirements for heartbeats and elections, leading to cluster instability and API server timeouts.

The primary solution is always to improve the underlying disk performance (e.g., by upgrading to a faster SSD).

However, if that is not immediately possible, you can make `etcd` more tolerant of latency by increasing its default timeouts.

## Configuration

To apply these settings, add the following `extraArgs` to the `etcd` section of your Talos `machineconfig.yaml.j2` file:

```yaml
cluster:
  etcd:
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381
      # Default: 100
      heartbeat-interval: "250"
      # Default: 1000
      election-timeout: "2500"
```

### Parameter Explanation

*   **`heartbeat-interval`** (in milliseconds): This controls how often the `etcd` leader sends heartbeats to its followers. Increasing this value gives the leader more time between heartbeats, making it less sensitive to short latency spikes. The value should be around 80% of the `election-timeout`.

*   **`election-timeout`** (in milliseconds): This is the amount of time a follower will wait without hearing from a leader before it attempts to start a new election. Increasing this value makes the cluster more tolerant to a leader that is temporarily unresponsive due to high load or slow disk I/O.

**Warning:** These settings do **not** fix the root cause of slow disk performance. They are a "band-aid" to improve cluster stability in a suboptimal hardware environment. The best long-term solution is to address the I/O bottleneck directly.
