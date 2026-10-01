# 职责: for 目标星形、嵌套、下标属性与解包错误文案
# 比对: same_output

# for 目标的星形名 / 嵌套 / 字符串解包 / 下标与属性目标 (P1-59)
for *h, t in ([[1, 2], [3]],):
    print(h, t)

for x, *y in [(1, 2, 3), (4,)]:
    print(x, y)

for *a, in [[1, 2], [3]]:
    print(a)

for p, q in [(1, 2), (3, 4)]:
    print(p, q)

for m, (n, o) in [(1, (2, 3))]:
    print(m, n, o)

for [c, d] in [[5, 6]]:
    print(c, d)

# 字符串元素按字符解包
for ch1, ch2 in ["xy", "ab"]:
    print(ch1, ch2)

# 下标目标与属性目标
arr = [10, 20]
for arr[0] in range(3):
    pass
print(arr)


class Box:
    pass


b = Box()
for b.v in range(2):
    pass
print(b.v)

# 解包错误文案对齐 CPython
try:
    for a1, b1 in [5]:
        pass
except TypeError as e:
    print("TE:", e)
try:
    for a2, b2 in [(1, 2, 3)]:
        pass
except ValueError as e:
    print("VE:", e)
try:
    for a3, b3 in [(1,)]:
        pass
except ValueError as e:
    print("VE2:", e)
try:
    a4, b4 = None
except TypeError as e:
    print("TE2:", e)
try:
    a5, b5 = 5
except TypeError as e:
    print("TE3:", e)
try:
    a6, = (1, 2)
except ValueError as e:
    print("VE3:", e)

# 循环变量在函数局部作用域的静态收集
def collect():
    total = 0
    for *part, last in [(1, 2, 3), (4, 5)]:
        total += sum(part) + last
    return total


print(collect())
