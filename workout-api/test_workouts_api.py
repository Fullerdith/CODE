import asyncio
from contextlib import asynccontextmanager
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import delete, text
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

from database import DATABASE_URL, get_db
from main import app
from models import Workout


TEST_DATABASE_NAME = "fastapi_test"

test_database_url = make_url(DATABASE_URL).set(database=TEST_DATABASE_NAME)
test_engine = create_async_engine(
    test_database_url,
    echo=False,
    poolclass=NullPool,
)
test_session_factory = async_sessionmaker(
    test_engine,
    expire_on_commit=False,
)


@asynccontextmanager
async def checked_test_session():
    async with test_session_factory() as session:
        result = await session.execute(text("SELECT DATABASE()"))
        database_name = result.scalar_one()
        assert database_name == TEST_DATABASE_NAME, (
            f"预期连接 {TEST_DATABASE_NAME}，实际连接 {database_name}"
        )
        yield session


async def override_get_db():
    async with checked_test_session() as session:
        yield session


@pytest.fixture
def client():
    previous_override = app.dependency_overrides.get(get_db)
    app.dependency_overrides[get_db] = override_get_db

    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        if previous_override is None:
            app.dependency_overrides.pop(get_db, None)
        else:
            app.dependency_overrides[get_db] = previous_override


async def create_workouts(workouts):
    async with checked_test_session() as session:
        session.add_all(workouts)
        await session.commit()
        return [workout.id for workout in workouts]


async def delete_workouts(workout_ids):
    async with checked_test_session() as session:
        for workout_id in workout_ids:
            workout = await session.get(Workout, workout_id)
            if workout is not None:
                await session.delete(workout)

        await session.commit()


async def delete_workout_by_name(exercise_name):
    async with checked_test_session() as session:
        await session.execute(
            delete(Workout).where(Workout.exercise_name == exercise_name)
        )
        await session.commit()

async def restore_workout_data(workout_id, original_data):
    async with checked_test_session() as session:
        workout = await session.get(Workout, workout_id)            
        if workout is not None:
            workout.weight = original_data["weight"]
            workout.reps = original_data["reps"]
            workout.exercise_name = original_data["exercise_name"]
            await session.commit()

async def get_workout_data(workout_id):
    async with checked_test_session() as session:
        workout = await session.get(Workout, workout_id)
        if workout is not None:
            return {
                "weight": workout.weight,
                "reps": workout.reps,
                "exercise_name": workout.exercise_name
            }
        return None


@pytest.fixture
def workout_id():
    workouts = [Workout(exercise_name="Test Exercise", weight=60.0, reps=10)]
    created_ids = asyncio.run(create_workouts(workouts))

    try:
        yield created_ids[0]
    finally:
        asyncio.run(delete_workouts(created_ids))


@pytest.fixture
def workout_ids():
    workouts = [
        Workout(exercise_name="Exercise 1", weight=50.0, reps=10),
        Workout(exercise_name="Exercise 2", weight=60.0, reps=12),
        Workout(exercise_name="Exercise 3", weight=70.0, reps=8),
        Workout(exercise_name="Exercise 4", weight=80.0, reps=15),
        Workout(exercise_name="Exercise 5", weight=90.0, reps=5),
        Workout(exercise_name="Exercise 6", weight=100.0, reps=20),
        Workout(exercise_name="Exercise 7", weight=110.0, reps=10),
        Workout(exercise_name="Exercise 8", weight=120.0, reps=10),
        Workout(exercise_name="Exercise 9", weight=130.0, reps=10),
        Workout(exercise_name="Exercise 10", weight=140.0, reps=10),
        Workout(exercise_name="Exercise 11", weight=150.0, reps=10),
        Workout(exercise_name="Exercise 12", weight=160.0, reps=10),
    ]
    created_ids = asyncio.run(create_workouts(workouts))

    try:
        yield created_ids
    finally:
        asyncio.run(delete_workouts(created_ids))

@pytest.fixture(scope="module")
def shared_workout_baseline(shared_workout_id):

    original_data = asyncio.run(
        get_workout_data(shared_workout_id)
    )

    if original_data is None:
        raise ValueError("共享记录不存在")

    return original_data

@pytest.fixture(scope="module")
def shared_workout_id():
    workouts = [
        Workout(
            exercise_name="Shared Exercise",
            weight=50.0,
            reps=10
        )
    ]
    created_ids = asyncio.run(create_workouts(workouts))

    try:
        yield created_ids[0]
    finally:
        asyncio.run(delete_workouts(created_ids))

@pytest.fixture
def restore_workout(shared_workout_id,shared_workout_baseline):
    
    try:
        yield shared_workout_id

    finally:    
        asyncio.run(restore_workout_data(shared_workout_id, shared_workout_baseline))
        actual_data = asyncio.run(get_workout_data(shared_workout_id))
        assert actual_data == shared_workout_baseline, (
            f"Workout with ID {shared_workout_id} was not restored to its original state."
        )

def assert_workout_page(response, workout_ids, page, page_size):
    assert response.status_code == 200
    data = response.json()

    assert data["page"] == page
    assert data["page_size"] == page_size
    assert data["total"] == len(workout_ids)

    offset = (page - 1) * page_size
    # The route orders rows by Workout.id before applying pagination.
    expected_ids = sorted(workout_ids)[offset : offset + page_size]
    actual_ids = [item["id"] for item in data["items"]]

    assert actual_ids == expected_ids


@pytest.mark.parametrize(
    "params",
    [
        {"page": 0, "page_size": 5},
        {"page": 1, "page_size": 0},
        {"page": 1, "page_size": 101},
        {"page": -1, "page_size": 10},
    ],
)
def test_invalid_pagination_params_return_422(client, params):
    response = client.get("/workouts", params=params)

    assert response.status_code == 422


@pytest.mark.parametrize("page_size", [1, 100])
def test_get_workouts_by_valid_page_and_size(client, workout_ids, page_size):
    page = 1
    response = client.get(
        "/workouts",
        params={"page": page, "page_size": page_size},
    )

    assert_workout_page(response, workout_ids, page, page_size)


def test_get_workouts_page_two(client, workout_ids):
    page = 2
    page_size = 5
    response = client.get(
        "/workouts",
        params={"page": page, "page_size": page_size},
    )

    assert_workout_page(response, workout_ids, page, page_size)


@pytest.mark.parametrize(
    "pages_after_last",
    [
        pytest.param(0, id="last-page"),
        pytest.param(1, id="immediately-beyond-last-page"),
    ],
)
def test_get_workouts_last_and_beyond_last_page(
    client, workout_ids, pages_after_last
):
    page_size = 5
    last_page = (len(workout_ids) + page_size - 1) // page_size
    page = last_page + pages_after_last

    response = client.get(
        "/workouts",
        params={"page": page, "page_size": page_size},
    )

    assert_workout_page(response, workout_ids, page, page_size)


def test_get_workouts_beyond_last_page(client, workout_ids):
    page = 9999
    page_size = 5
    response = client.get(
        "/workouts",
        params={"page": page, "page_size": page_size},
    )

    assert_workout_page(response, workout_ids, page, page_size)


def test_get_workout_with_id(client, workout_id):
    response = client.get(f"/workouts/{workout_id}")

    assert response.status_code == 200
    assert response.json()["id"] == workout_id


def test_get_workout_with_nonexistent_id(client, workout_id):
    asyncio.run(delete_workouts([workout_id]))

    response = client.get(f"/workouts/{workout_id}")

    assert response.status_code == 404


def test_get_workout_with_invalid_id(client):
    response = client.get("/workouts/abc")

    assert response.status_code == 422


def test_create_workout(client):
    payload = {
        "exercise_name": f"Bench Press {uuid4().hex}",
        "weight": 60.0,
        "reps": 10,
    }

    try:
        response = client.post("/workouts", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["id"], int)
        assert data["id"] > 0
        assert data["exercise_name"] == payload["exercise_name"]
        assert data["weight"] == payload["weight"]
        assert data["reps"] == payload["reps"]
    finally:
        asyncio.run(delete_workout_by_name(payload["exercise_name"]))


def test_delete_workout(client, workout_id):
    url = f"/workouts/{workout_id}"

    delete_response = client.delete(url)
    assert delete_response.status_code == 200

    get_response = client.get(url)
    assert get_response.status_code == 404


def test_update_weight(client, restore_workout):
    payload = {"weight": 70.0}
    response = client.patch(f"/workouts/{restore_workout}", json=payload)

    assert response.status_code == 200
    data = response.json()
    assert data["exercise_name"] == "Shared Exercise"
    assert data["weight"] == payload["weight"]
    assert data["reps"] == 10

def test_update_reps(client, restore_workout):
    payload = {"reps": 20}

    response = client.patch(
        f"/workouts/{restore_workout}",
        json=payload
    )

    assert response.status_code == 200
    assert response.json()["reps"] == 20


def test_update_nonexistent_workout_returns_404(client, workout_id):
    url = f"/workouts/{workout_id}"

    delete_response = client.delete(url)
    assert delete_response.status_code == 200

    update_response = client.patch(url, json={"weight": 70.0})
    assert update_response.status_code == 404


def test_create_workout_missing_reps(client):
    payload = {"exercise_name": "Squat", "weight": 80.0}
    response = client.post("/workouts", json=payload)

    assert response.status_code == 422


@pytest.mark.parametrize(
    "payload, expected_type, expected_loc",
    [
        (
            {"weight": 60.0, "reps": 10},
            "missing",
            ["body", "exercise_name"],
        ),
        (
            {"exercise_name": "Squat", "weight": "heavy", "reps": 8},
            "float_parsing",
            ["body", "weight"],
        ),
        (
            {"exercise_name": "Deadlift", "weight": 100.0, "reps": "abc"},
            "int_parsing",
            ["body", "reps"],
        ),
    ],
)
def test_create_workout_invalid_payload(
    client, payload, expected_type, expected_loc
):
    response = client.post("/workouts", json=payload)

    assert response.status_code == 422
    error = response.json()["detail"][0]
    assert error["type"] == expected_type
    assert error["loc"] == expected_loc


def test_workout_ids_fixture(workout_ids):
    assert len(workout_ids) == 12
    assert len(set(workout_ids)) == len(workout_ids)