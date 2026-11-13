from fastapi import APIRouter, Depends, HTTPException,Query
from sqlalchemy.ext.asyncio import AsyncSession
from schemas import WorkoutCreate, WorkoutRead,WorkoutUpdate, WorkoutPage
from database import get_db
from models import Workout
from sqlalchemy import select,func

router = APIRouter()

@router.post("/workouts", response_model=WorkoutRead)
async def create_workout(workout: WorkoutCreate, db: AsyncSession = Depends(get_db)):
    new_workout = Workout(**workout.model_dump())
    db.add(new_workout)
    await db.commit()
    await db.refresh(new_workout)
    return new_workout

#@router.get("/workouts", response_model=list[WorkoutRead])
#async def get_workouts(db: AsyncSession = Depends(get_db)):
#    result = await db.execute(select(Workout))
#   workouts = result.scalars().all()
#    return workouts

@router.get("/workouts/{workout_id}", response_model=WorkoutRead)
async def get_workout(workout_id: int,db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Workout).where(Workout.id==workout_id ))
    workout = result.scalar_one_or_none()
    if workout is None:
        raise HTTPException(status_code=404, detail="Workout not found")
    return workout

@router.patch("/workouts/{workout_id}", response_model=WorkoutRead)
async def update_workout(workout_id: int, workout_update: WorkoutUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Workout).where(Workout.id == workout_id))
    workout = result.scalar_one_or_none()
    if workout is None:
        raise HTTPException(status_code=404, detail="Workout not found")
    
    workout_update = workout_update.model_dump(exclude_unset=True)

    for key, value in workout_update.items():
        setattr(workout, key, value)

    await db.commit()
    await db.refresh(workout)
    return workout

@router.delete("/workouts/{workout_id}", response_model=WorkoutRead)
async def delete(workout_id: int,db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Workout).where(Workout.id==workout_id))
    workout = result.scalar_one_or_none()
    if workout is None:
        raise HTTPException(status_code=404, detail="Workout not found")
    await db.delete(workout)
    await db.commit()
    return workout

@router.get("/workouts",response_model=WorkoutPage)
async def get_workouts_paginated(page: int = Query(1, ge=1),
                                  page_size: int = Query(10, ge=1, le=100),
                                    db: AsyncSession = Depends(get_db)):
    offset = (page - 1) * page_size
    result = await db.execute(select(Workout)
                              .offset(offset)
                              .limit(page_size)
                              .order_by(Workout.id))
    workouts = result.scalars().all()

    total_result = await db.execute(func.count().select().select_from(Workout))
    total = total_result.scalar_one()

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "items": workouts
    }
