# 数组与函数 — 完整答案

**姓名**: 赵俊涛 | **时长**: 150分钟 | **截止**: 2026-06-06 11:14

---

## 一、单选题 (9题, 18分)

| 题号 | 答案 | 解析 |
|------|------|------|
| Q1 | **B** | p无\0长度不确定；q部分初始化，未赋值部分为\0，长度为3 |
| Q2 | **A** | gets(ss)用"ABC"覆盖了"12345"，strcat连接"6789"得"ABC6789" |
| Q3 | **D** | k=1输出w[1]="EFGH"，k=2输出w[2]="IJKL" |
| Q4 | **B** | strlen遇\0停止=5；sizeof是数组总字节数=20 |
| Q5 | **C** | x用字符串赋值自动加\0(长8)，y逐个字符赋值无\0(长7) |
| Q6 | **B** | scanf地址列表：b用&b，数组c用数组名c即可 |
| Q7 | **A** | gets在strcat之后执行，用"ABC"覆盖，只输出"ABC" |
| Q8 | **C** | for循环i=0时ch[0]='6'满足条件，s=6；i=2时ch[2]='a'不满足退出 |
| Q9 | **A** | C程序必须有main()函数 |

---

## 二、编程题 (8题, 82分)

### Q10: 字符串排序 (10分) — C语言

```c
#include <stdio.h>
#include <string.h>

int main()
{
    char str[5][80], temp[80];
    int i, j;
    
    for (i = 0; i < 5; i++) {
        scanf("%s", str[i]);
    }
    
    // 冒泡排序
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4 - i; j++) {
            if (strcmp(str[j], str[j+1]) > 0) {
                strcpy(temp, str[j]);
                strcpy(str[j], str[j+1]);
                strcpy(str[j+1], temp);
            }
        }
    }
    
    printf("After sorted:\n");
    for (i = 0; i < 5; i++) {
        printf("%s\n", str[i]);
    }
    
    return 0;
}
```

---

### Q11: 求三个实数中的最大值 (10分)

```cpp
/*********Program*********/
double max(double a, double b, double c)
{
    double m = a;
    if (b > m) m = b;
    if (c > m) m = c;
    return m;
}
/*********  End  *********/
```

---

### Q12: 计算汇款收费 (10分)

```cpp
/**********Program**********/
double fee = money * 0.01;
if (fee > 50) fee = 50;
return fee;
/**********  End  **********/
```

---

### Q13: 判断各位数字是否包含3或4 (10分)

```cpp
/**********Program**********/
if (n < 0) n = -n;        // 取绝对值
while (n > 0) {
    int digit = n % 10;
    if (digit == 3 || digit == 4)
        return true;
    n /= 10;
}
return false;
/**********  End  **********/
```

---

### Q14: 求最大值和次最大值并交换 (10分)

```cpp
/**********Program**********/
max = a[0]; m = 0;
// 找最大值位置
for (i = 1; i < 10; i++) {
    if (a[i] > max) {
        max = a[i];
        m = i;
    }
}
// 交换最大值到a[0]
t = a[0]; a[0] = a[m]; a[m] = t;

// 找次大值位置(从1开始)
cmax = a[1]; n = 1;
for (i = 2; i < 10; i++) {
    if (a[i] > cmax) {
        cmax = a[i];
        n = i;
    }
}
// 交换次大值到a[1]
t = a[1]; a[1] = a[n]; a[n] = t;
/**********  End  **********/
```

---

### Q15: 最大公约数 (12分)

```cpp
/*********Program*********/
int temp;
while (n != 0) {
    temp = m % n;
    m = n;
    n = temp;
}
return m;
/*********  End  *********/
```

---

### Q16: 计算级数 (10分)

```cpp
/**********Program**********/
if (k == 1)
    return 1.0;
else
    return 1.0/k + m(k - 1);
/**********  End  **********/
```

---

### Q17: 求数列和 (10分)

```cpp
/**********Program**********/
// 斐波那契: 0,1,1,2,3,5,8,13,...
// 前20项: a1=0, a2=1, a3=a1+a2, ...
for (k = 3; k <= 20; k++) {
    int next = a1 + a2;
    s += next;
    a1 = a2;
    a2 = next;
}
/**********  End  **********/
```

---
