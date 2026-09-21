# 多 for 推导式测试 (含多 if 子句, Python 3.x)

# 双 for 列表推导式
print([x * y for x in [1, 2] for y in [10, 20]])        # [10, 20, 20, 40]

# 嵌套顺序与 for 语句一致
print([(x, y) for x in [1, 2] for y in ["a", "b"]])     # [(1, 'a'), (1, 'b'), (2, 'a'), (2, 'b')]

# 内层可引用外层变量
print([x + y for x in range(3) for y in range(x)])      # [1, 2, 3]

# 多 if 子句
print([x for x in range(10) if x % 2 == 0 if x > 4])    # [6, 8]

# 每个 for 各自带 if
print([x * y for x in range(5) if x % 2 == 1 for y in range(3) if y != 1])

# 三 for
print([x + y + z for x in [1] for y in [2] for z in [3, 4]])

# 集合推导式 (多 for)
print(sorted({x * y for x in [1, 2] for y in [2, 3]}))

# 字典推导式 (多 for)
print({x: y for x in [1, 2] for y in [10, 20]})

# 字典推导式: 元组目标解包 + 条件
print({k: v for k, v in [("a", 1), ("b", 2)] if v > 1})

# 列表推导式: 元组目标解包
print([k for k, v in [("a", 1), ("b", 2)]])
print([v * 10 for k, v in [("a", 1), ("b", 2)]])

# 生成器表达式 (多 for)
g = (x * y for x in [1, 2] for y in [10, 20])
print(type(g))                  # <class 'generator'>
print(list(g))                  # [10, 20, 20, 40]

# 生成器表达式: 多 if
print(list(x for x in range(10) if x % 3 == 0 if x > 0))

# 生成器惰性: 无限迭代源 + 多子句
from itertools import count, islice
print(list(islice((x * y for x in count(1) for y in [1, 2]), 5)))

# 生成器表达式: 元组目标
print(list(k for k, v in [("a", 1), ("b", 2)]))

print("done")
