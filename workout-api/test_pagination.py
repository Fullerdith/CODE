import pytest
from pagination import calculate_offset


@pytest.mark.parametrize(
    ("page", "page_size", "expected"),
    [
        (1, 10, 0),
        (2, 5, 5),
        (3, 7, 14),
        (4, 6, 18),
    ],
)
def test_calculate_offset(page, page_size, expected):
    assert calculate_offset(page, page_size) == expected