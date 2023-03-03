# About the "host" variable

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
