# Setup energizta.sh

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
