from fastapi import FastAPI

app = FastAPI()
a = "t"


@app.get("/")
async def main() -> dict[str, str]:
    return {"Hello": "Ciprian"}
