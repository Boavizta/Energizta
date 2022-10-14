from typing import List, Union, Optional

from pydantic import BaseModel


class CPU(BaseModel):
    name: str
    core_units: str


class RAM(BaseModel):
    vendor: Optional[str] = None
    capacity: float


class Disk(BaseModel):
    type: str
    vendor: str
    capacity: float


class Hardware(BaseModel):
    cpus: Union[CPU, List[CPU]]
    rams: Union[RAM, List[RAM]]
    disks: Union[Disk, List[Disk]]


class StressResult(BaseModel):
    batch_id: str
    type: str
    power_type: str
    load: float
    power: float


class Benchmark(BaseModel):
    device_id: str
    contributor: str
    hardware: Hardware
    stress_results: List[StressResult]
    date: str
