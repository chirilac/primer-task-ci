from fastapi import FastAPI
import os

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello from Primer Task", "version": os.getenv("APP_VERSION", "unknown")}


@app.get("/health")
async def health():
    return {"status": "healthy"}
