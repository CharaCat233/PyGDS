# 集合推导式测试 {expr for var in iterable [if cond]}

# 基本集合推导式
print({x * x for x in [1, 2, 3, 2]})       # {1, 4, 9} (自动去重)
print(sorted({x * x for x in [1, 2, 3, 2]}))  # [1, 4, 9]

# 带条件
print(sorted({x for x in range(6) if x % 2 == 0}))  # [0, 2, 4]
print(sorted({x for x in range(5) if x > 1}))       # [2, 3, 4]

# 元素为字符串
print(sorted({s.upper() for s in ["a", "b", "a"]}))  # ['A', 'B']

# range 迭代
print(sorted({x % 3 for x in range(10)}))       # [0, 1, 2]

# 函数调用
print(sorted({len(s) for s in ["a", "bb", "ccc"]}))  # [1, 2, 3]

print("done")
