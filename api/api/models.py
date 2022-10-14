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
    cpus: Optional[List[CPU]] = [CPU()]
    rams: Optional[List[RAM]] = [RAM()]
    disks: Optional[List[Disk]] = [Disk()]


class Power(BaseModel):
    source: Optional[str] = None
    scope: Optional[str] = None
    value: Optional[float] = None


class State(BaseModel):
    type: Optional[str] = None
    powers: Optional[List[Power]] = [Power()]
    temperature: Optional[float] = None
    disks_io: Optional[float] = None
    ram_io: Optional[float] = None
    cpu_percent_user: Optional[float] = None
    cpu_percent_sys: Optional[float] = None
    cpu_percent_iowait: Optional[float] = None
    netstats: Optional[float] = None


class Record(BaseModel):
    device_id: Optional[str] = None
    contributor: Optional[str] = None
    hardware: Optional[Hardware] = Hardware()
    states: Optional[List[State]] = [State()]
    date: Optional[str] = None


if __name__ == '__main__':
    import json

    print(json.dumps(Record().dict(), indent=4))
