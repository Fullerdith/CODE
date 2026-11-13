from sqlalchemy import String, Float
from sqlalchemy.orm import Mapped, mapped_column
from database import Base

class Workout(Base):
    __tablename__ = "workouts"

    id:Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    exercise_name:Mapped[str] = mapped_column(String(100), nullable=False)
    weight:Mapped[float] = mapped_column(Float)
    reps:Mapped[int] = mapped_column()