# energizta.sh

**Warning:** this is still a very early stage project. Any feedback or contribution will be highly appreciated.

energizta.sh is a simple script that focuses on retrieving every information that can be used to guess the power consumption of baremetal servers *with as much precision as possible*

It will try and find all power metrics available. Some are partials (RAPL), some should be global (DCMI, lm-sensors, PDU…) and some could even be inputed by a user looking at a wattmeter. The primary goal is to get all data possible for scientists to work on models.

This first version has been written in bash4 and does not depend on anything else. The goal is to provide a simple script that can be run by anyone on any recent Linux server.

## How to install

## How to use

```
./energizta.sh --help
sudo ./energizta.sh
```

## Stresstest

TODO

## How to run in the background

TODO

## How to send us your results!

TODO

## Other similar projets :

 - Scaphandre : https://github.com/hubblo-org/scaphandre
 - PowerJoular : https://gitlab.com/joular/powerjoular
