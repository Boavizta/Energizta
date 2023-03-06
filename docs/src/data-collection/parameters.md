# Main options

```bash
--interval INTERVAL   Measure server state each INTERVAL seconds (default 5)
--duration DURATION   Stop each stresstest after DURATION seconds (default 60)
--once                Do not loop, print one state and exit
--manual-input        Ask the user to enter power metrics manually (from a Wattmeter…)

--debug               Display debug outputs
--continuous          Display the current state every INTERVAL seconds instead of an average state every DURATION seconds
--energy-only         Only displays energy variables instead of global state (load, cpu, etc.)
--with_timestamp      Include timestamp in displayed variables
--with_date           Include datetime in displayed variables
--short-host-id       Use shorter string as HOST_ID and avoid the need for lshw (not compatible with --send-     to-db)
--force-host-id ID    Force an alternative HOST_ID, use $(hostname) for instance (not compatible with --send-    to-db)

```

> This script should not be used with an INTERVAL lower than 1 because each loop can take 500ms so it can cause significant load. Also, the greater the INTERVAL between each loop, the lower the margin of error on interval dependant measures (disk usage, RAPL power). With that said, some metrics are realtime metrics (temp, dcmi, used mem), so the greater the interval, the least those metrics are representative of the period. I believe a 2 to 10s INTERVAL is ideal.
