# Quickstart for energita's contributers

```bash
wget https://raw.githubusercontent.com/Boavizta/Energizta/main/energizta/energizta.sh
chmod +x energizta.sh
sudo apt-get install awk sed curl lshw stress-ng

sudo ./energizta.sh --stresstest --send-to-db
```

This will run a series of [stress tests](stress-test-mode.md) while collecting power consumption data and then [send the collected data to the energizta-db.boavizta.org database](send-data.md) with your consent. If your machine has not yet sent any data, energizta.sh will collect [a series of variables](host-variables.md) to characterize the technical configuration of the host.

```ignore
-- 2023-03-03 18:13:46 - INFO: This test should take 240s
-- 2023-03-03 18:13:46 - INFO: Running "sleep 120" for 60 seconds
{"host": "d04e0818-3d98-41ad-b516-7b735809a0bf_1f9684433f690826ce392919c8022beb_82e8c7a4c323a6df478f95c0683fb084","interval_us": 6400207,"duration_us": 51201667,"nb_states": 8,"cpu_iowait_pct": 0,"cpu_sys_pct": 2,"cpu_usr_pct": 97,"load1": 11.61,"mem_free_MB": 2099,"mem_total_MB": 7708,"mem_used_MB": 2339,"sda_pct_busy": 4,"sda_read_kBps": 1271,"sda_write_kBps": 198,"powers": {"rapl_dram_0_watt": 1,"rapl_package_0_watt": 8,"rapl_total_watt": 9},"energizta_version": "0.1a"}
 
-- 2023-03-03 18:16:11 - INFO: Running "stress-ng -q --cpu 4" for 60 seconds
1ad-b516-7b735809a0bf_1f9684433f690826ce392919c8022beb_82e8c7a4c323a6df478f95c0683fb084","interval_us": 6457377,"duration_us": 51659033,"nb_states": 8,"cpu_iowait_pct": 0,"cpu_sys_pct": 2,"cpu_usr_pct": 97,"load1": 13.35,"mem_free_MB": 2133,"mem_total_MB": 7708,"mem_used_MB": 2317,"sda_pct_busy": 0,"sda_read_kBps": 3,"sda_write_kBps": 202,"powers": {"rapl_dram_0_watt": 0,"rapl_package_0_watt": 8,"rapl_total_watt": 8},"energizta_version": "0.1a"}

... 

-- 2023-03-03 18:21:24 - INFO: Running "stress-ng -q --cpu 8" for 60 seconds
{"host": "d04e0818-3d98-41ad-b516-7b735809a0bf_1f9684433f690826ce392919c8022beb_82e8c7a4c323a6df478f95c0683fb084","interval_us": 6602975,"duration_us": 52823821,"nb_states": 8,"cpu_iowait_pct": 0,"cpu_sys_pct": 0,"cpu_usr_pct": 99,"load1": 17.32,"mem_free_MB": 2076,"mem_total_MB": 7708,"mem_used_MB": 2330,"sda_pct_busy": 0,"sda_read_kBps": 104,"sda_write_kBps": 139,"powers": {"rapl_dram_0_watt": 0,"rapl_package_0_watt": 8,"rapl_total_watt": 8},"energizta_version": "0.1a"}
 
=> Do you still want to send above data to Boavizta's Energizta database? (y/n) y
 
Checking if d04e0818-3d98-41ad-b516-7b735809a0bf_1f9684433f690826ce392919c8022beb_82e8c7a4c323a6df478f95c0683fb084 is registered in Boavizta's Energizta database…
We need to register some information about your hardware and software.
It should be completely anonymous:


"id": "d04e0818-3d98-41ad-b516-7b735809a0bf_1f9684433f690826ce392919c8022beb_82e8c7a4c323a6df478f95c0683fb084",
"hardware": [
...
],
"software": {...}
}

=> Do you allow to register this on Boavizta's Energizta database? (y/n) y

Registering d04e0818-3d98-41ad-b516-7b735809a0bf_1f9684433f690826ce392919c8022beb_82e8c7a4c323a6df478f95c0683fb084 in Boavizta's Energizta database…
This host is now registered.

Sending results to Energizta collaborative database…

Done. Thank you!
```
