from fastapi import APIRouter, UploadFile

route = APIRouter(
    prefix='/v1',
)


@route.post('/upload_benchmark')
async def upload_benchmark(file: UploadFile) -> None:
    pass
