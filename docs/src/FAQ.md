# FAQ

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
