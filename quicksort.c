#include <stdio.h>
#include <string.h>

#define CHAR_LEN 5   /* 每个字符串长度固定为5 */
#define MAX_N   100  /* 最大数组容量 */

/* 交换两个字符串 */
void swap(char a[], char b[]) {
    char tmp[CHAR_LEN + 1];
    strcpy(tmp, a);
    strcpy(a, b);
    strcpy(b, tmp);
}

/* 分区：以最后一个元素为基准 */
int partition(char arr[][CHAR_LEN + 1], int low, int high) {
    char pivot[CHAR_LEN + 1];
    strcpy(pivot, arr[high]);
    int i = low - 1;

    for (int j = low; j < high; j++) {
        if (strcmp(arr[j], pivot) < 0) {
            i++;
            swap(arr[i], arr[j]);
        }
    }
    swap(arr[i + 1], arr[high]);
    return i + 1;
}

/* 快速排序递归函数 */
void quicksort_impl(char arr[][CHAR_LEN + 1], int low, int high) {
    if (low < high) {
        int pi = partition(arr, low, high);
        quicksort_impl(arr, low, pi - 1);
        quicksort_impl(arr, pi + 1, high);
    }
}

/* 对外接口 */
void quicksort(char arr[][CHAR_LEN + 1], int n) {
    quicksort_impl(arr, 0, n - 1);
}

int main() {
    char arr[][CHAR_LEN + 1] = {
        "hello", "world", "abcde", "xyzab", "china", "aaaaa", "zzzzz"
    };
    int n = sizeof(arr) / sizeof(arr[0]);

    printf("排序前: ");
    for (int i = 0; i < n; i++) printf("%s ", arr[i]);

    quicksort(arr, n);

    printf("\n排序后: ");
    for (int i = 0; i < n; i++) printf("%s ", arr[i]);
    printf("\n");

    return 0;
}
