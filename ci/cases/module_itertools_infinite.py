# 职责: repeat/cycle/count/takewhile
# 比对: same_output

# itertools 扩展测试: repeat / cycle / count / zip_longest / takewhile / dropwhile

from itertools import repeat, cycle, count, zip_longest, takewhile, dropwhile, islice

# repeat 指定次数
print(list(repeat(5, 3)))  # [5, 5, 5]
print(list(repeat("a", 2)))  # ['a', 'a']
print(list(repeat(7, 0)))  # []

# repeat 无限形式 + islice
print(list(islice(repeat(9), 4)))  # [9, 9, 9, 9]

# cycle 循环
print(list(islice(cycle([1, 2, 3]), 5)))  # [1, 2, 3, 1, 2]
print(list(islice(cycle("ab"), 4)))  # ['a', 'b', 'a', 'b']

# count 计数
print(list(islice(count(), 4)))  # [0, 1, 2, 3]
print(list(islice(count(10, 5), 4)))  # [10, 15, 20, 25]
print(list(islice(count(-2), 3)))  # [-2, -1, 0]

# zip_longest 以最长为准
print(list(zip_longest([1, 2], [3], fillvalue=0)))  # [(1, 3), (2, 0)]
print(
    list(zip_longest([1], [2, 3], [4, 5, 6]))
)  # [(1, 2, 4), (None, 3, 5), (None, None, 6)]
print(
    list(zip_longest("ab", "cde", fillvalue="?"))
)  # [('a', 'c'), ('b', 'd'), ('?', 'e')]

# takewhile 取开头满足条件
print(list(takewhile(lambda x: x < 4, [1, 2, 5, 3, 4])))  # [1, 2]
print(list(takewhile(lambda x: x % 2 == 0, [2, 4, 1, 6])))  # [2, 4]
print(list(takewhile(lambda x: x > 0, [])))  # []

# dropwhile 丢弃开头满足条件
print(list(dropwhile(lambda x: x < 3, [1, 2, 3, 4, 1])))  # [3, 4, 1]
print(list(dropwhile(lambda x: x == "a", ["a", "a", "b"])))  # ['b']
print(list(dropwhile(lambda x: x < 0, [1, 2, 3])))  # [1, 2, 3]


# count/cycle/repeat 一次性迭代语义 (此前可重复迭代从头开始)
# 对象缓存共享迭代器; count 大数起始/步长任意精度

# iter(c) is c
c1 = count(3)
print(iter(c1) is c1)
c2 = cycle([1, 2])
print(iter(c2) is c2)
r1 = repeat(9)
print(iter(r1) is r1)

# 跨语句 next 丢进度修复 (此前重建游标从头来)
k = count(3)
print(next(k))
print(next(k))
print(next(k))

# 跨语句消费 cycle / repeat
c3 = cycle([1, 2])
next(c3)
print(list(islice(c3, 3)))
r2 = repeat(7)
next(r2)
print(list(islice(r2, 2)))

# islice 消费后继续 (一次性游标)
c4 = count(3)
print(list(islice(c4, 2)))
print(list(islice(c4, 2)))

# count 大数起始/步长 (此前从 0 计数)
cb = count(10**30)
print(next(cb))
print(next(cb))
cs = count(0, 10**30)
print(next(cs))
print(next(cs))

# count 浮点步长保型
cf = count(0.5, 0.5)
print(list(islice(cf, 3)))

# 负大数起始
cn = count(-(10**30))
print(next(cn))
print(next(cn))

# islice 下标校验 (此前负参数/浮点/大数静默接受)
# CPython: 三类下标须为 None 或 [0, sys.maxsize] 整数, 浮点/负数/超界报 ValueError
try:
    list(islice([1, 2, 3], -1))
except ValueError as e:
    print("VE-islice1:", e)
try:
    list(islice([1, 2, 3], -1, 2))
except ValueError as e:
    print("VE-islice2:", e)
try:
    list(islice([1, 2, 3], 0, 2, 0))
except ValueError as e:
    print("VE-islice3:", e)
try:
    list(islice([1, 2, 3], 0, 2, -1))
except ValueError as e:
    print("VE-islice4:", e)
try:
    list(islice([1, 2, 3], 1.5))
except ValueError as e:
    print("VE-islice5:", e)
try:
    list(islice([1, 2, 3], 10**100))
except ValueError as e:
    print("VE-islice6:", e)
print(list(islice([1, 2, 3], True)))
print(list(islice([1, 2, 3], 1, None, 2)))
print(list(islice([1, 2, 3], None)))
print(list(islice([1, 2, 3], 1, 3)))
print(list(islice([1, 2, 3], 0, None, 2)))
