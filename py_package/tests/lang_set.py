# set 类型测试: 字面量 / 构造 / 方法 / 运算 / 比较

# 集合字面量与基本操作
s = {1, 2, 3}
print(sorted(s))         # [1, 2, 3]
print(len(s))            # 3
print(2 in s)            # True
print(5 in s)            # False
s.add(4)
print(sorted(s))         # [1, 2, 3, 4]
s.discard(1)
print(sorted(s))         # [2, 3, 4]
s.remove(3)
print(sorted(s))         # [2, 4]
print(3 in s)            # False

# 重复元素去重
print(sorted({1, 1, 2, 2, 3}))  # [1, 2, 3]
print(len({1, 1, 1}))     # 1

# 空集合
empty = set()
print(len(empty))        # 0
print(len(set()))        # 0

# 集合运算
a = {1, 2, 3}
b = {2, 3, 4}
print(sorted(a | b))     # [1, 2, 3, 4]
print(sorted(a & b))     # [2, 3]
print(sorted(a - b))     # [1]
print(sorted(a ^ b))     # [1, 4]
print(sorted(a.union(b)))           # [1, 2, 3, 4]
print(sorted(a.intersection(b)))    # [2, 3]
print(sorted(a.difference(b)))      # [1]
print(sorted(a.symmetric_difference(b)))  # [1, 4]

# 相等与不等 (内容比较, 与顺序无关)
print({1, 2} == {2, 1})   # True
print({1, 2} == {1, 3})   # False
print({1} != {2})         # True
print({1, 2} == {1, 2, 3})  # False

# 子集 / 超集 / 不相交
print({1, 2} < {1, 2, 3})  # True
print({1, 2} <= {1, 2})    # True
print({1, 2, 3} > {1})     # True
print({1, 2} >= {2})       # True
print({1}.issubset({1, 2}))       # True
print({1, 2}.issuperset({2}))     # True
print({1, 2}.isdisjoint({3}))     # True
print({1, 2}.isdisjoint({1}))     # False

# 构造与转换
print(sorted(set([1, 1, 2, 2, 3])))   # [1, 2, 3]
print(sorted(set("abca")))            # ['a', 'b', 'c']
print(sorted(set([1, 2, 3]) - {2}))   # [1, 3]

# copy / clear
s1 = {1, 2}
s2 = s1.copy()
print(s2 == s1)           # True
print(s1 == {1, 2})       # True
s1.clear()
print(len(s1))            # 0
print(s2 == {1, 2})       # True

# pop
p = {7}
print(p.pop())            # 7
print(len(p))             # 0

# isinstance
print(isinstance({1}, set))   # True
print(isinstance([], set))    # False

# 集合推导式可通过构造实现 (set of squares)
print(sorted(set([x * x for x in [1, 2, 3, 2]])))  # [1, 4, 9]

print("done")
