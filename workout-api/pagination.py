def calculate_offset(page: int, page_size: int) -> int:
    offset = (page - 1) * page_size
    return offset