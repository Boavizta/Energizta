# How to run in the background (with systemd)

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
