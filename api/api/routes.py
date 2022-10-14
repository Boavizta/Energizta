import pandas as pd
from fastapi import APIRouter

from api.models import Record


route = APIRouter(
    prefix='/v1',
)


@route.post('/upload_record')
async def record(rec: Record) -> None:
    static_record = [{
        'batch_id': rec.batch_id,
        'device_id': rec.device_id,
        'contributor': rec.contributor,
        'date': rec.date
    }]

    cpu_record = []
    for cpu in rec.hardware.cpus:
        cpu_record.append({
            "batch_id": rec.batch_id,
            "name": cpu.name,
            "core_units": cpu.core_units
        })

    ram_record = []
    for ram in rec.hardware.rams:
        ram_record.append({
            "batch_id": rec.batch_id,
            "vendor": ram.vendor,
            "capacity": ram.capacity
        })

    disk_record = []
    for disk in rec.hardware.disks:
        disk_record.append({
            "batch_id": rec.batch_id,
            "type": disk.type,
            "vendor": disk.vendor,
            "capacity": disk.capacity
        })

    state_records = []
    for state in rec.states:
        state_dict = state.dict()
        state_dict.pop('powers')
        for power in state.powers:
            state_records.append({**{
                'batch_id': rec.batch_id,
                'power_source': power.source,
                'power_scope': power.scope,
                'power_value': power.value,
            }, **state_dict})

    pd.DataFrame(static_record).to_csv('../../data/architecture.csv')
    pd.DataFrame(state_records).to_csv('../../data/record.csv')
    pd.DataFrame(cpu_record).to_csv('../../data/cpu.csv')
    pd.DataFrame(ram_record).to_csv('../../data/ram.csv')
    pd.DataFrame(disk_record).to_csv('../../data/disk.csv')
