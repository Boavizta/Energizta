<p align="center">
    <img src="https://boavizta.org/media/site/d84925bc94-1642413712/boavizta-logo-4.png" width="100">
</p>
<h1 align="center">
  🔌 Energizta
</h1>

---

A collaborative platform to aggregate consumption profiles.


## Consumption profile

A consumption profile is a continuous function that, for a given workload, returns an electrical consumption. They allow to model the power consumption of components.

$$
CP_{component} : \mathnormal{workload} \in [0,1] \mapsto \mathnormal{power} \in \mathbb{R^{+}}
$$

## Methodology

1. Aggregation of power consumption measurements on various architectures at different workload levels.

2. Identification of the main architectural characteristics in terms of power consumption 

3. Empirical production (throught regressions) of power consumption profiles by identified architecture type

### Exemple for CPU : Intel Xeon Platinium

<img width="854" alt="168429164-d5105376-0f25-4dea-a122-3c0d75555dfd" src="https://user-images.githubusercontent.com/24867893/190581083-9d14ff64-9732-4a86-8e16-c29a48a32e3b.png">

## :scroll: License

MIT
