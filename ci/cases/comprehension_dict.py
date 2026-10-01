# 职责: 字典推导式的键值构造、过滤与多重 for
# 比对: same_output

# 基本形态: 键值表达式
squares = {n: n * n for n in range(4)}
print(squares)                   # {0: 0, 1: 1, 2: 4, 3: 9}

# 值过滤与对 items 的过滤
odd_sq = {n: n * n for n in range(6) if n % 2 == 1}
print(odd_sq)                    # {1: 1, 3: 9, 5: 25}
filtered = {k: v for k, v in squares.items() if v > 1}
print(filtered)                  # {2: 4, 3: 9}

# 键值表达式使用元组解包目标
swapped = {v: k for k, v in [("a", 1), ("b", 2)]}
print(swapped)                   # {1: 'a', 2: 'b'}

# 多重 for: 后写的键覆盖先写的键
pairs = {x: y for x in range(2) for y in range(2)}
print(pairs)                     # {0: 1, 1: 1}

# 条件表达式作为值表达式
labels = {n: ("even" if n % 2 == 0 else "odd") for n in range(3)}
print(labels)                    # {0: 'even', 1: 'odd', 2: 'even'}

# 嵌套可迭代作为源
matrix = {i: row[0] for i, row in enumerate([[7, 8], [9, 10]])}
print(matrix)                    # {0: 7, 1: 9}

# 嵌套推导式作为源
dt = {n - 2: n * 2 for n in [n for n in range(5) if n % 2 == 0] if n % 2 == 0}
print(dt)  # {-2: 0, 0: 4, 2: 8}
