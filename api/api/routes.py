from fastapi import APIRouter

from api.models import Record


route = APIRouter(
    prefix='/v1',
)


@route.post('/upload_record')
async def record(rec: Record) -> Record:
    return rec
