from typing import List, Union, Optional

from pydantic import BaseModel


class CPU(BaseModel):
    name: Optional[str] = None
    core_units: Optional[str] = None


class RAM(BaseModel):
    vendor: Optional[str] = None
    capacity: Optional[float] = None


class Disk(BaseModel):
    type: Optional[str] = None
    vendor: Optional[str] = None
    capacity: Optional[float] = None


class Hardware(BaseModel):
    cpus: Union[CPU, List[CPU]]
    rams: Union[RAM, List[RAM]]
    disks: Union[Disk, List[Disk]]


class StressResult(BaseModel):
    type: str
    dcmi_power: Optional[float] = None
    rapl_power: Optional[float] = None
    manual_power: Optional[float] = None
    temperature: Optional[float] = None
    disks_io: Optional[float] = None
    ram_io: Optional[float] = None
    cpu_percent_user: Optional[float] = None
    cpu_percent_sys: Optional[float] = None
    cpu_percent_iowait: Optional[float] = None
    netstats: Optional[float] = None


class Benchmark(BaseModel):
    device_id: str
    contributor: Optional[str] = None
    hardware: Hardware
    stress_results: List[StressResult]
    date: str
