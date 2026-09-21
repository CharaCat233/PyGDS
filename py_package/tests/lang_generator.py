# 生成器表达式测试 (惰性生成器)

from itertools import islice, count

# 类型
g = (x * x for x in range(5))
print(type(g))                  # <class 'generator'>

# 惰性: 未消费时不求值
print(list(x * x for x in range(5)))          # [0, 1, 4, 9, 16]
print(list(x for x in range(6) if x % 2 == 0))  # [0, 2, 4]

# tuple / 列表推导消费
print(tuple(x for x in range(3)))             # (0, 1, 2)
print([x for x in (x for x in "abc")])        # ['a', 'b', 'c']

# next() 逐次推进 (一次性迭代器)
g1 = (x for x in range(3))
print(next(g1))                 # 0
print(next(g1))                 # 1
print(list(g1))                 # [2] (继续, 已消费 0, 1)
print(list(g1))                 # [] (已耗尽)

# next() 默认值
g2 = (x for x in range(1))
print(next(g2, -1))             # 0
print(next(g2, -1))             # -1 (耗尽返回默认值)

# sum / sorted / min / max / any / all
print(sum(x * x for x in range(4)))           # 14
print(sorted(x for x in [3, 1, 2]))           # [1, 2, 3]
print(min(x for x in [5, 3, 9]))              # 3
print(max(x for x in [5, 3, 9]))              # 9
print(any(x > 2 for x in [1, 2, 3]))          # True
print(all(x > 0 for x in [1, 2, 3]))          # True

# enumerate / zip
print(list(enumerate((x for x in ["a", "b"]), start=1)))  # [(1, 'a'), (2, 'b')]
print(list(zip((x for x in [1, 2]), [10, 20])))           # [(1, 10), (2, 20)]

# islice 惰性消费无限生成器
print(list(islice((x for x in count(0, 2)), 4)))    # [0, 2, 4, 6]
print(list(islice((x * x for x in count()), 5)))    # [0, 1, 4, 9, 16]

print("done")
