# Changelog

## energizta.sh 0.5

**Features**

* Manage Grid5000 wattemeter using Grid5000 API and $OAR_JOB_ID variable (#23, thank you @jacquetpi:tab)

## energizta.sh 0.4

**Improvements*

* Improve int divisions to avoid rounding to inferior integer, which could compound to more than 1W error.

## energizta.sh 0.3

**Features**

* Manage Shelly Plug Smart Plug / Wattmeter (tested with Shelly Plug S)

## energizta.sh 0.2

**Features**

* Add `cpu_freq_mhz` variable
* Add network interfaces input/output variables : ex. `eth0_recv_kBps`, `eth0_recv_packetsps`, `eth0_sent_kBps`, `eth0_sent_packetsps`
* Manage psys zone in RAPL, add `powers.rapl_totalpsys_watt` variable when available

## energizta.sh 0.1

* First stable release : power mesures, state mesures, stress-tests.
