from typing import List, Union

from pydantic import BaseModel


class CPU(BaseModel):
    vendor: str
    name: str
    model_range: str
    core_units: str
    family: str


class RAM(BaseModel):
    vendor: str
    name: str
    capacity: float


class Disk(BaseModel):
    type: str
    vendor: str
    name: str
    capacity: float


class Hardware(BaseModel):
    cpus: Union[CPU, List[CPU]]
    rams: Union[RAM, List[RAM]]
    disks: Union[Disk, List[Disk]]
    motherboard: str


class StressResult(BaseModel):
    stress_type: str
    power_type: str
    timestamp: int
    load: float
    power: float


class Benchmark(BaseModel):
    device_id: str
    contributor: str
    hardware: Hardware
    stress_results: List[StressResult]
