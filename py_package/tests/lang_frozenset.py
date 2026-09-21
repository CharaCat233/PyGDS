# frozenset 不可变集合测试

# 基本构造
f = frozenset([1, 2, 2, 3])
print(len(f))                   # 3 (自动去重)
print(2 in f)                   # True
print(5 in f)                   # False
print(sorted(f))                # [1, 2, 3]

# 空 frozenset
e = frozenset()
print(len(e))                   # 0
print(list(e))                  # []

# 从 set / 字符串构造
print(sorted(frozenset({1, 2, 3})))   # [1, 2, 3]
print(sorted(frozenset("aabbc")))     # ['a', 'b', 'c']

# 相等与比较 (与顺序无关, 可与 set 比较)
print(frozenset([1, 2, 3]) == frozenset([3, 2, 1]))  # True
print(frozenset([1, 2]) == frozenset([1, 2, 3]))     # False
print(frozenset([1, 2]) == {1, 2})                    # True (与 set 相等)
print(frozenset([1, 2]) != frozenset([1, 3]))        # True

# 集合运算 (返回 frozenset)
a = frozenset([1, 2, 3])
b = frozenset([2, 3, 4])
print(sorted(a | b))            # [1, 2, 3, 4]
print(sorted(a & b))            # [2, 3]
print(sorted(a - b))            # [1]
print(sorted(a ^ b))            # [1, 4]

# 与 set 混合运算
print(sorted(frozenset([1, 2]) | {2, 3}))   # [1, 2, 3]
print(sorted(frozenset([1, 2]) & {2}))      # [2]

# 子集关系
print(frozenset([1, 2]) <= frozenset([1, 2, 3]))   # True
print(frozenset([1, 2]) < frozenset([1, 2, 3]))    # True
print(frozenset([1, 2, 3]) > frozenset([1]))       # True
print(frozenset([1]).issubset(frozenset([1, 2])))  # True
print(frozenset([1, 2]).issuperset(frozenset([2])))# True

# 方法: union/intersection/difference (返回 frozenset)
print(sorted(a.union(b)))            # [1, 2, 3, 4]
print(sorted(a.intersection(b)))     # [2, 3]
print(sorted(a.difference(b)))       # [1]
print(sorted(a.symmetric_difference(b)))  # [1, 4]

# copy
f2 = frozenset([1, 2])
f3 = f2.copy()
print(f3 == f2)                      # True
print(len(f3))                       # 2

# 可哈希: 作为 set 元素去重
s = {frozenset([1, 2]), frozenset([2, 1]), frozenset([1, 2, 3])}
print(len(s))                        # 2 (前两个去重)

# isinstance
print(isinstance(frozenset([1]), frozenset))   # True
print(isinstance({1}, frozenset))              # False
print(isinstance(frozenset([1]), set))         # False

print("done")
