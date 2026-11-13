# 训练记录 API

使用 FastAPI、异步 SQLAlchemy 和 MySQL 管理训练记录，提供增删改查和按 ID 排序的分页查询。

## 本地运行

需要 Python 3.10+ 和 MySQL。先创建一个空数据库 `workout_db`，再复制 `.env.example` 为 `.env`，填写本机数据库连接。不要提交实际口令。

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python create_tables.py
uvicorn main:app --reload
```

启动后访问 http://127.0.0.1:8000/docs 查看接口并尝试请求。

## 接口

- `POST /workouts` 创建训练记录
- `GET /workouts/{id}` 查看记录
- `PATCH /workouts/{id}` 更新提供的字段，字段不能显式传 null
- `DELETE /workouts/{id}` 删除记录并返回原记录
- `GET /workouts?page=1&page_size=10` 分页查询，返回总数和记录

请求体示例

```json
{"exercise_name": "Bench press", "weight": 60, "reps": 8}
```

## 测试

`pytest test_pagination.py` 运行不依赖数据库的分页计算测试。API 测试使用 MySQL 中的 `fastapi_test` 数据库，先创建该空数据库和表，并在隔离环境运行。测试会创建和删除测试记录，分页断言依赖测试库为空。

```powershell
pytest test_pagination.py
pytest test_workouts_api.py
```

当前项目没有用户认证，适合本机学习。建表脚本使用 SQLAlchemy `create_all`，不会迁移已有表结构。
