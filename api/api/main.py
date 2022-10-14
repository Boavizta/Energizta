from fastapi import FastAPI

from api.routes import route

app = FastAPI()

app.include_router(route)


if __name__ == '__main__':
    import uvicorn

    uvicorn.run('main:app', host='localhost', port=5000, reload=True, debug=True)
