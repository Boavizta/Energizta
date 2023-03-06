# Stress test mode

To get the most various data, Energizta can run stress tests to put your server in various load level. It will make your server work at 10%, 50%, 100%… and take measurement for each state.

To do this we use https://github.com/ColinIanKing/stress-ng

On Debian : `sudo apt-get install stress-ng`

```bash
sudo ./energizta.sh --stresstest [--debug]
```

By default, it will run… TODO

### Alternate stress tests

If you want to run your own stress tests, you can do it by providing your own file. Each line of the file should be a stress test command that will run for at least DURATION seconds (because you don't want your stress test to stop before the measurements…). The command does not have to stop by itself, `energizta.sh` will kill it after DURATION seconds.

```bash
sudo ./energizta.sh --stressfile my_stress_tests.txt
```
