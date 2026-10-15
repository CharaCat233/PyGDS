# 职责: list 构造、增删改查方法与 +/* 运算
# 比对: same_output


# list 构造函数
a = list([1, 2, 3])
print(a)  # [1, 2, 3]

# list.append
a.append(4)
print(a)  # [1, 2, 3, 4]

# list.extend
a.extend([5, 6])
print(a)  # [1, 2, 3, 4, 5, 6]

# list.pop
last = a.pop()
print(last, a)  # 6 [1, 2, 3, 4, 5]

first = a.pop(0)
print(first, a)  # 1 [2, 3, 4, 5]

# list.insert
a.insert(0, 99)
print(a)  # [99, 2, 3, 4, 5]

# list.remove
a.remove(3)
print(a)  # [99, 2, 4, 5]

# list.index
print(a.index(99))  # 0
print(a.index(5))  # 3

# list.count
dup = list([1, 2, 2, 3, 2])
print(dup.count(2))  # 3
print(dup.count(9))  # 0

# list.copy
b = a.copy()
a[0] = 0
print(a)  # [0, 2, 4, 5]
print(b)  # [99, 2, 4, 5]

# list.reverse
b.reverse()
print(b)  # [5, 4, 2, 99]

# list.sort
b.sort()
print(b)  # [2, 4, 5, 99]

# list.clear
b.clear()
print(b)  # []

# list 二元运算
x = list([1, 2])
y = list([3, 4])
print(x + y)  # [1, 2, 3, 4]
print(x * 3)  # [1, 2, 1, 2, 1, 2]
print(x == y)  # False
print(x != y)  # True
print(y == [3, 4])  # True
print(y == list([3, 4]))  # True

# list + 原始 list
raw = [10, 20]
new_ls = x + raw
x[0] = 2026
raw[0] = 2026
print(x)  # [2026, 2]
print(raw)  # [2026, 20]
print(new_ls)  # [1, 2, 10, 20]

# list.index 的 start/end 参数 (此前忽略静默返回错误下标)
try:
    print([1, 2, 3].index(1, 1))
except ValueError as e:
    print("VE-start:", str(e))

try:
    print([1, 2, 3].index(3, 0, 2))
except ValueError as e:
    print("VE-end:", str(e))

print([1, 2, 3].index(2, 1))
print([1, 2, 3].index(3, -1))
print([1, 2, 3].index(1, 0, 2))
print([1, 2, 3].index(1, -3))
print([1, 2, 3].index(2, 1, 3))

# tuple.index 的 start/end 同步
try:
    print((1, 2, 3).index(1, 1))
except ValueError as e:
    print("VE-tup:", str(e))

print((1, 2, 3).index(2, 1))

# list.pop/insert 大数下标 (此前大数 value=0 弹首元素/插头部)
try:
    print([1, 2, 3].pop(10**100))
except OverflowError as e:
    print("OE-pop:", str(e))

try:
    l = [7, 8]
    l.insert(10**100, 0)
    print(l)
except OverflowError as e:
    print("OE-ins:", str(e))

print([1, 2, 3].pop(True))
l2 = [7, 8]
l2.insert(True, 0)
print(l2)

# list.pop 负索引 (此前负索引一律报 IndexError, 应从尾部计数)
print([1, 2, 3].pop(-2))
p = [1, 2, 3]
print(p.pop(-3))
print(p)
try:
    [1, 2, 3].pop(-9)
except IndexError as e:
    print("IE:", e)


# 空列表 pop 文案 (CPython 先查空再查越界, 显式下标亦报 "pop from empty list")
def _show_exc(label, fn):
    try:
        fn()
        print(label, "OK")
    except IndexError as e:
        print(label, type(e).__name__, str(e))


_show_exc("pop_empty", lambda: [].pop())
_show_exc("pop_empty0", lambda: [].pop(0))
_show_exc("pop_empty5", lambda: [].pop(5))
_show_exc("pop_oor", lambda: [1, 2].pop(5))
_show_exc("pop_oor_neg", lambda: [1, 2].pop(-3))
