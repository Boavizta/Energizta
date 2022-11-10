# Energizta


Energizta is a collaborative project to collect and report open-data on the energy consumption of IT equipments.

**Warning: this is still a very early stage project. Any feedback or contribution will be highly appreciated.**


Science is still at an early stage for computer energy consumption measurement. Most energy consumption metrology agents take a simplified approach and estimate that CPU+RAM consumption represents the majority of power consumption on most common servers (CPU, RAM, SSD or disk… no GPU). That's because, at first glance, what will mostly impact power consumption is the CPU load, and because this is a metric that we can get on all recent Intel and AMD CPUs with a tool named RAPL.

It is harder to measure (or estimate) true power consumption:
- The IPMI (DCMI) can provide the power consumption of the power supply unit, but we don't know for sure how this metric is calculated. And access to DCMI seems to be is very rare on public baremetal hosters, so it is a metric we cannot get on every dedicated server.
- `lm-sensors` can provide the ACPI power, but again it seems to be very rare and we don't know how this metric is calculated, more search is needed.
- A PDU could provide the data, but baremetal clients do not have access to datacenters PDU.
- Wattmeters between the server and its power plug could provide the data, but obviously we don't have that on public baremetal servers.

The first tests to compare RAPL measurements (CPU+RAM) to total power consumption (with DCMI or wattmeter) seems to indicate that true power can be between 1 and 10x what we get with RAPL (again, on standard dedicated server without GPU). That should be expected. On an idle host, CPU and RAM can consume 5W so "fixed costs" (HDD, SSD…) become more important. Then we could talk about power supply loss, etc.

Moreover, its it not always possible to access RAPL data. It needs recent Linux kernel, recent hardware, and root access. And it needs a monitoring agent to log data frequently, because you cannot ask RAPL once a year what the consumption has been in the last year.

So how do we bridge these gaps? Can we guess the true total power based on RAPL only? Maybe add some fixed costs for hardware? Maybe we should add storage IOs? Network? Maybe temperature can help? How much precision can we get with partial informations? How precisely can we estimate a baremetal server yearly power consumption with only hardware specs and load average?


Energizta is trying to address these problems and provide a set of tools to guess the power consumption of a baremetal servers *with as much precision as possible*.


## How?

1. With a script that will focus on retrieving every information that can be used to guess the power consumption of baremetal servers *with as much precision as possible*.
2. With a "citizen science" database were anyone can contribute by uploading the information returned by the script. This database will be opendata and should allow research scientists to work on models and equations to describe power usage based upon hardware specs and server load (realtime or average).
3. With an API that will compile the result of the models and equations to provide power consumption estimation based upon what's available to the user given it's context.

Examples of goals:

- I have a server with an Intel Xeon E3-1240v6, 32GB RAM, 2 500GB SSD. I know last year it had a load average of 3. Can we tell how much energy it has consume? With what precision? Looking at existing data for similar hardware, we should at least be able to provide a minimum and a maximum.
- I am running a metrology agent on the same server (Xeon…, 32GB RAM… etc.). RAPL tells me that right now I have 14W in the CPU+RAM, I have a load1 of 3, 14%cpu_user, 10%cpu_sys, 0%cpu_iowait, 5GB RAM used, etc… but I don't have access to IPMI. Can we tell the global power usage? Again, with what precision?


## FAQ

### Shouldn't this be done at another level?

Yes, of course. Power usage should be provided by the datacenter or the hoster, and we believe (hope?) it will be, pretty soon, because the clients will start to ask for it.

But for now, it's not. And even when it will be, how can you tell if the value you get seems to be right? Take the previous example: "I have a server with an Intel Xeon E3-1240v6, 32GB RAM, 2 500GB SSD. I know last year it had a load average of 3." Can you guess the power consumption?
Well, we have discussed. Some will tell 20W, some will tell 60W, some will tell 200W.

We need to get an feeling for the numbers we are looking at and working with. And this projet should at least get us there.


### Is it all I need to calculate my carbon emissions?

No, of course not. This projet will only help to measure or estimate the power consumption of a given server. To get to the scope 2 you should add at least the datacenter P.U.E., and then look at the carbon emissions of the energy mix.

But then you need to get to the scope 3 and look at the server fabrication and life cycle.


### What about cloud usage? What about VM? How can I know how my application consume?

This projet focuses on baremetal servers because it is the original brick on which everything else is built. We think it is important to get this as precisely as possible.

There is a lot of projets that work to guess power usage by VM, cloud instance, container, application, etc.

- Scaphandre : https://github.com/hubblo-org/scaphandre
- BoAgent : https://github.com/Boavizta/boagent
- …
