# energizta.sh

**Warning:** this is still a very early stage project. Any feedback or contribution will be highly appreciated.

`energizta.sh` is a simple script that focuses on retrieving every information that can be used to guess the power consumption of baremetal servers *with as much precision as possible*

It will try and find all power metrics available. Some are partial (RAPL), some should be global (DCMI, lm-sensors, PDU…) and some could even be inputed by a user looking at a wattmeter. The primary goal is to get all data possible for scientists to work on models.

This first version has been written in Bash4 and does not depend on anything else. The goal is to provide a simple script that can be run by anyone on any recent Linux server.

## How to install

```
wget https://raw.githubusercontent.com/Boavizta/Energizta/main/energizta/energizta.sh
chmod +x energizta.sh
sudo apt-get install awk sed curl lshw
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

```

> This script should not be used with an INTERVAL lower than 1 because each loop can take 500ms so it can cause significant load. Also, the greater the INTERVAL between each loop, the lower the margin of error on interval dependant measures (disk usage, RAPL power). With that said, some metrics are realtime metrics (temp, dcmi, used mem), so the greater the interval, the least those metrics are representative of the period. I believe a 2 to 10s INTERVAL is ideal.

## Stresstest

To get the most various data, Energizta can run stress tests to put your server in various load level. It will make your server work at 10%, 50%, 100%… and take measurement for each state.

To do this we use https://github.com/ColinIanKing/stress-ng

On Debian : `sudo apt-get install stress-ng`

```
sudo ./energizta.sh --stresstest [--debug]
```

By default, it will run… TODO

### Alternate stress tests

If you want to run your own stress tests, you can by providing a file. Each line of the file should be a stress test command that will run for at least DURATION seconds (because you don't want your stress test to stop before the measurements…). The command does not have to stop by itself, `energizta.sh` will kill it after DURATION seconds.

```
sudo ./energizta.sh --stressfile my_stress_tests.txt
```

### Options

```
--stresstest          Run a stresstest
--stressfile FILEPATH Load alternative stress tests commands from a file instead of default stresstest
--warmup WARMUP       Wait WARMUP seconds after lauching a stresstest before measuring state (default 20)
```

## How to send us your results!

The main goal of this tool is to stresstest your computer or baremetal server, and send the results to Energizta collaborative database. It will also send the hardware and OS.

```
sudo ./energizta.sh --stresstest --send-to-db
```

The data sent to the collaborative database should be completely anonymous and should not be enough to identify your computer or server (no hostname, no IP, no MAC, etc.). The script will display and ask you for confirmation before sending data.


### About the "host" variable

The "host" variable will be used in our database to group states by host, to study one host, or to exclude one host of the study.

It is composed of 3 parts:

- the UUID of the `/` partition. This UUID will not change between runs and should be unique to your computer. But it is also completely anonymous and cannot be used to identify your computer on the internet. That's why we did not use the hostname of the mac address.
- the md5sum of the hardware : `lshw -short` (with some filtering)
- the md5sum of the software : `arch`, `uname -a` (minus hostname) and `lsb_release -ds`

The idea is that hardware and software upgrade can affect power consumption, so we need to group the states under a different ID.

If you want a shorter id, or a custom id, you can use :

```
--short-host-id       Use shorter string as HOST_ID and avoid the need for lshw
--force-host-id ID    Force an alternative HOST_ID, use $(hostname) for instance
```

These options are not compatible with `--send-to-db`.


## How to run in the background (with systemd)

First, move `energizta.sh` to `/usr/local/sbin/energizta.sh`.

Then, create a new file `/etc/systemd/system/energizta.service`

```
[Unit]
Description=Energizta

[Service]
ExecStart=/usr/local/sbin/energizta.sh --interval 10 --duration 60 --short-host-id
ExecStart=/bin/sh -c '/usr/local/sbin/energizta.sh --interval 10 --duration 60 --with-timestamp --with-date --short-host-id >> /var/lib/energizta/energizta.log'

[Install]
WantedBy=multi-user.target
```

Then activate and run the service

```
systemctl daemon-reload
systemctl enable energizta
systemctl start energizta
tail -f /var/log/energizta.log
```

Please be aware that `energizta.sh` outputs JSON lines that can take a lot of space overtime. You should use `--duration` set the duration between each log (60s by default). And you should configure logrotate accordingly.

> Also be aware that due to the current implementation, `energizta.sh` ends up having a load of variables after a few days which can cause significative load. You should restart this daemon at least once a day.


## Other similar projets :

 - Scaphandre : https://github.com/hubblo-org/scaphandre
 - PowerJoular : https://gitlab.com/joular/powerjoular
