def quicksort(arr):
    """快速排序（原地排序版本）"""
    def _quicksort(arr, low, high):
        if low < high:
            pi = partition(arr, low, high)
            _quicksort(arr, low, pi - 1)
            _quicksort(arr, pi + 1, high)

    def partition(arr, low, high):
        pivot = arr[high]  # 选最后一个元素作为基准
        i = low - 1        # 小于 pivot 的元素的边界
        for j in range(low, high):
            if arr[j] < pivot:
                i += 1
                arr[i], arr[j] = arr[j], arr[i]
        arr[i + 1], arr[high] = arr[high], arr[i + 1]
        return i + 1

    _quicksort(arr, 0, len(arr) - 1)


def quicksort_simple(arr):
    """快速排序（简洁版，返回新数组）"""
    if len(arr) <= 1:
        return arr
    pivot = arr[0]
    left = [x for x in arr[1:] if x < pivot]
    right = [x for x in arr[1:] if x >= pivot]
    return quicksort_simple(left) + [pivot] + quicksort_simple(right)


if __name__ == "__main__":
    # 测试整数
    arr1 = [3, 6, 8, 10, 1, 2, 1]
    print("原地排序前:", arr1)
    quicksort(arr1)
    print("原地排序后:", arr1)

    arr2 = [5, 2, 9, 1, 5, 6]
    print("\n简洁版排序:", quicksort_simple(arr2))

    # 测试5字符字符串
    arr3 = ["hello", "world", "abcde", "xyzab", "china"]
    print("\n5字符字符串排序前:", arr3)
    quicksort(arr3)
    print("5字符字符串排序后:", arr3)
