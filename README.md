# Energizta

Energizta is a collaborative project to collect and report open-data on the energy consumption of servers.

**Warning: this is still a very early stage project. Any feedback or contribution will be highly appreciated.**

## What

Science is still at an early stage for computer energy consumption evaluation.

Several approaches have been used to measure (or model) the power consumption of computers:

- RAPL can be used on all recent Intel and AMD CPUs. Most energy consumption metrology agents use it to estimate CPU+RAM consumption which represents the majority of power consumption on most common servers (CPU, RAM, SSD or disk… no GPU). Its it not always possible to access RAPL data. It needs recent Linux kernel, recent hardware, and root access. And it needs a monitoring agent to log data frequently, because you cannot ask RAPL once a year what the consumption has been in the last year. Besides, in environment such as public cloud or VM you can not access RAPL interfaces.

- The IPMI (DCMI) can provide the power consumption of the power supply unit, but we don't know for sure how this metric is calculated. And access to DCMI seems to be very rare on public bare-metal hosters, so it is a metric we cannot get on every dedicated server.

- `lm-sensors` can provide the ACPI power, but again it seems to be very rare, and we don't know how this metric is calculated, more search is needed.

- A PDU could provide the data, but most users do not have access to datacenters PDU.

- Wattmeters between the server and its power plug could provide the data, but obviously we don't have that on public baremetal servers.

- Model have been developed to retrieve consumption data from proxy metrics. They often use data from spec_power or from unormalized data collection process. Unfortunately, the level of granularity is often not fine enough to infer quality models.

These different methods give different result on the same environment. For instance, the first tests to compare RAPL measurements (CPU+RAM) to total power consumption (with DCMI or watt meter) seems to indicate that the global power can be between 1 and 10x what we get with RAPL (again, on standard dedicated server without GPU).

So how do we bridge these gaps? Can we guess the total power based on RAPL only? Maybe add some fixed costs for hardware? Maybe we should add storage IOs? Network? Maybe temperature can help? How much precision can we get with partial information? How precisely can we estimate server yearly power consumption with only hardware specs and proxy metrics?

Energizta is trying to address these problems and provide a set of tools to report and model the power consumption of servers *with as much precision as possible*.


## How?

1. With a script that collect hardware configurations and retreive power consumption metrics on baremetal servers at differents states with differents methods.
2. With a "citizen science" database where anyone can contribute by uploading the information returned by the script. This database will be opendata and should allow research scientists to work on models and equations to describe power usage based upon hardware specs proxy metrics (realtime or average).
3. With an API that will compile the result of the models and equations to provide power consumption estimation based upon what's available to the user given it's context.

Examples of goals:

- I have a server with an Intel Xeon E3-1240v6, 32GB RAM, 2 500GB SSD. I know last year it had a load average of 3. Can we tell how much energy it has consume? With what precision? Looking at existing data for similar hardware, we should at least be able to provide a minimum and a maximum power consumption.
- I am running a metrology agent on the same server (Xeon…, 32GB RAM… etc.). RAPL tells me that right now I have 14W in the CPU+RAM, I have a load1 of 3, 14%cpu_user, 10%cpu_sys, 0%cpu_iowait, 5GB RAM used, etc… but I don't have access to IPMI. Can we tell the global power usage? Again, with what precision?
- I have an AWS EC2 a1.medium instance. I know my average cpu load from AWS API. Looking at existing data for similar hardware, we should at least be able to provide a minimum and a maximum power consumption.


## FAQ

### Shouldn't this be done at another level?

Yes, of course. Power usage should be provided by the datacenter or the hoster, and we believe (hope?) it will be, pretty soon, because the clients will start to ask for it.

But for now, it's not. And even when it will be, how can you tell if the value you get seems to be right? Take the previous example: "I have a server with an Intel Xeon E3-1240v6, 32GB RAM, 2 500GB SSD. I know last year it had a load average of 3." Can you guess the power consumption?
Well, we have discussed. Some will tell 20W, some will tell 60W, some will tell 200W.

We need to get a feeling for the numbers we are looking at and working with. And this project should at least get us there.


### Is it all I need to calculate environmental impacts?

No, of course not. This project will only help to measure or model the power consumption of a given server. To get to the impacts related to usage, you should add at least the datacenter P.U.E., and then look at the impacts of the energy mix of the location where the server run.

But you should also include the other step of the lifecycle of servers such as raw material extraction, manufacture, transport and end of life.

Finally, you should not only look at the green gas emissions but have a multi-criteria approach by taking into account other impacts such as abiotic depletion, water usage, ...



### What about cloud usage? What about VM? How can I know how my application consume?

This is a matter of allocations : How to allocate the impacts of a physical element (servers) to the different function it fulfills ? Since we only focus on a physical layer (servers) this question is out of the scope of the project.

See our approach for cloud : https://doc.dev.api.boavizta.org/Explanations/devices/cloud/
