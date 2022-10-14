from fastapi import APIRouter

from api.models import Benchmark


route = APIRouter(
    prefix='/v1',
)


@route.post('/upload_benchmark')
async def benchmark(bench: Benchmark) -> Benchmark:
    return bench
