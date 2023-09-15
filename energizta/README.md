# energizta.sh :satellite:

**:warning: This is still a very early stage project. Any feedback or contribution will be highly appreciated. :warning:**

`energizta.sh` is a simple script that focuses on retrieving every information that can be used to guess the power consumption of baremetal servers *with as much precision as possible*

It will try and find all power metrics available. Some are partial (RAPL), some should be global (DCMI, lm-sensors, PDU…) and some could even be inputed by a user looking at a wattmeter. The primary goal is to get all data possible for scientists to work on models.

This first version has been written in Bash4 and does not depend on anything else. The goal is to provide a simple script that can be run by anyone on any recent Linux server.

## How to install

```
wget https://raw.githubusercontent.com/Boavizta/Energizta/main/energizta/energizta.sh
chmod +x energizta.sh
sudo apt-get install sed curl lshw stress-ng bc
```

## How to use

```
./energizta.sh --help
sudo ./energizta.sh
```

It will run until you use Ctrl+C to stop it.

`energizta.sh` gives you various options that are documented in `./energizta --help`

### Main options

```
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

--ipmi-sensor-id ID   Name of sensor to get power from in `ipmitool sensor`
--shellyplug-url URL  Shelly Plug URL (ex: http://192.168.33.1 or http://admin:password@192.168.33)

--stresstest          Run a stresstest
--stressfile FILEPATH Load alternative stress tests commands from a file instead of default stresstest
--warmup WARMUP       Wait WARMUP seconds after lauching a stresstest before measuring state (default 20)

```

> This script should not be used with an INTERVAL lower than 1 because each loop can take 500ms so it can cause significant load. Also, the greater the INTERVAL between each loop, the lower the margin of error on interval dependant measures (disk usage, RAPL power). With that said, some metrics are realtime metrics (temp, dcmi, used mem), so the greater the interval, the least those metrics are representative of the period. I believe a 2 to 10s INTERVAL is ideal.

## Stress test mode ♨️

https://boavizta.github.io/Energizta/data-collection/stress-test-mode.html


## How to send us your results 📧

https://boavizta.github.io/Energizta/data-collection/send-data.html

## Host variables 💻

https://boavizta.github.io/Energizta/data-collection/host-variables.html

## How to run in the background (with systemd) ◀️

https://boavizta.github.io/Energizta/data-collection/run-energizta-in-background.html
