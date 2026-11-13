import pytest
from pydantic import ValidationError

from schemas import WorkoutUpdate


def test_update_accepts_omitted_fields():
    update = WorkoutUpdate(weight=70)
    assert update.model_dump(exclude_unset=True) == {"weight": 70.0}


@pytest.mark.parametrize("field", ["exercise_name", "weight", "reps"])
def test_update_rejects_explicit_null(field):
    with pytest.raises(ValidationError):
        WorkoutUpdate(**{field: None})
