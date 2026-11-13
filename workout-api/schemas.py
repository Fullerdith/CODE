from pydantic import BaseModel, ConfigDict, model_validator

class WorkoutCreate(BaseModel):
    exercise_name : str
    weight : float
    reps : int

class WorkoutRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id : int
    exercise_name : str
    weight : float
    reps : int

class WorkoutUpdate(BaseModel):
    exercise_name : str | None = None
    weight : float | None = None
    reps : int | None = None

    @model_validator(mode="after")
    def reject_explicit_null(self):
        for field in self.model_fields_set:
            if getattr(self, field) is None:
                raise ValueError(f"{field} cannot be null")
        return self

class WorkoutPage(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    total: int
    page: int
    page_size: int
    items: list[WorkoutRead]
