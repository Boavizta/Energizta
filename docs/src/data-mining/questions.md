# Questions to be answered

To help you understand how to use the data collected in energizta, here is a list of questions we would like to answer.

- I have a server with an Intel Xeon E3-1240v6, 32GB RAM, 2 500GB SSD. I know last year it had a load average of 3. Can we tell how much energy it has consume? With what precision? Looking at existing data for similar hardware, we should at least be able to provide a minimum and a maximum power consumption. [See Boaviztapi's consumption profile for more information on this use case](https://doc.api.boavizta.org/Explanations/consumption_profile/)

- I am running a metrology agent on the same server (Xeon…, 32GB RAM… etc.). RAPL tells me that right now I have 14W in the CPU+RAM, I have a load1 of 3, 14%cpu_user, 10%cpu_sys, 0%cpu_iowait, 5GB RAM used, etc… but I don't have access to IPMI. Can we tell the global power usage? Again, with what precision?

- I have an AWS EC2 a1.medium instance. I know my average cpu load from AWS API. Looking at existing data for similar hardware, we should at least be able to provide a minimum and a maximum power consumption. [See cloud-scanner for more information on this use-case](https://boavizta.github.io/cloud-scanner/intro.html)
