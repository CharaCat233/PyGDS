# Builtin: list 操作


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
