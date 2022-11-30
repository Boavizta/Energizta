# energizta.sh

**Warning:** this is still a very early stage project. Any feedback or contribution will be highly appreciated.

`energizta.sh` is a simple script that focuses on retrieving every information that can be used to guess the power consumption of baremetal servers *with as much precision as possible*

It will try and find all power metrics available. Some are partial (RAPL), some should be global (DCMI, lm-sensors, PDU…) and some could even be inputed by a user looking at a wattmeter. The primary goal is to get all data possible for scientists to work on models.

This first version has been written in Bash4 and does not depend on anything else. The goal is to provide a simple script that can be run by anyone on any recent Linux server.

## How to install

```
sudo apt-get install jq # That should be removed in final version
wget https://raw.githubusercontent.com/Boavizta/Energizta/main/energizta/energizta.sh
chmod +x energizta.sh
```

## How to use

```
./energizta.sh --help
sudo ./energizta.sh
```

It will run until you use Ctrl+C to stop it.

`energizta.sh` gives you various options that are documented in `./energizta --help`

### Options

```
--interval INTERVAL   Measure server state each INTERVAL seconds (default 5)
--duration DURATION   Stop each stresstest after DURATION seconds (default 60)
--manual-input        Ask the user to enter power metrics manually (from a Wattmeter…)

--debug               Display debug outputs
--continuous          Display the current state every INTERVAL seconds instead of an average state every DURATION seconds
--energy-only         Only displays energy variables instead of global state (load, cpu, etc.)
```

> This script should not be used with an INTERVAL lower than 1 because each loop can take 500ms so it can cause significant load. Also, the greater the INTERVAL between each loop, the lower the margin of error on interval dependant measures (disk usage, RAPL power). With that said, some metrics are realtime metrics (temp, dcmi, used mem), so the greater the interval, the least those metrics are representative of the period. I believe a 2 to 10s INTERVAL is ideal.

## Stresstest

To get the most various data, Energizta can run stress tests to put your server in various load level. I will make your server work at 10%, 50%, 100%… and take measurement for each state.

To do this we use https://github.com/ColinIanKing/stress-ng

On Debian : `sudo apt-get install stress-ng`

```
./energizta.sh --stresstest [--debug]
```

By default, it will run… TODO

### Alternate stress tests

If you want to run your own stress tests, you can by providing a file. Each line of the file should be a stress test command that will run for at least DURATION seconds (because you don't want your stress test to stop before the measurements…). The command does not have to stop by itself, `energizta.sh` will kill it after DURATION seconds.

```
./energizta.sh --stressfile my_stress_tests.txt
```

### Options

```
--stresstest          Run a stresstest
--stressfile FILEPATH Load alternative stress tests commands from a file instead of default stresstest
--warmup WARMUP       Wait WARMUP seconds after lauching a stresstest before measuring state (default 20)
```


## How to run in the background (with systemd)

First, move `energizta.sh` to `/usr/local/sbin/energizta.sh`.

Then, create a new file `/etc/systemd/system/energizta.service`

```
[Unit]
Description=Energizta

[Service]
ExecStart=/usr/local/sbin/energizta.sh --interval 10 --duration 60
StandardOutput=file:/var/log/energizta.log

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


## How to send us your results!

TODO

## Other similar projets :

 - Scaphandre : https://github.com/hubblo-org/scaphandre
 - PowerJoular : https://gitlab.com/joular/powerjoular
