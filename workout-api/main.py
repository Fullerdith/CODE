from fastapi import APIRouter, Depends, HTTPException, FastAPI

app = FastAPI()

from routers.workouts import router

app.include_router(router)
