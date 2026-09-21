# itertools 补全测试: accumulate / pairwise / groupby / starmap

from itertools import accumulate, pairwise, groupby, starmap

# accumulate 前缀和
print(list(accumulate([1, 2, 3, 4])))                        # [1, 3, 6, 10]
print(list(accumulate([5])))                                 # [5]
print(list(accumulate([])))                                  # []
print(list(accumulate([1, 2, 3, 4], lambda a, b: a * b)))    # [1, 2, 6, 24]
print(list(accumulate(["a", "b", "c"])))                     # ['a', 'ab', 'abc']

# accumulate 带初始值
print(list(accumulate([1, 2, 3], initial=10)))               # [10, 11, 13, 16]
print(list(accumulate([1, 2], lambda a, b: a + b, initial=0)))  # [0, 1, 3]

# accumulate 与其他可迭代对象
print(list(accumulate(range(5))))                            # [0, 1, 3, 6, 10]

# pairwise 相邻对
print(list(pairwise([1, 2, 3, 4])))     # [(1, 2), (2, 3), (3, 4)]
print(list(pairwise([1])))              # []
print(list(pairwise([])))               # []
print(list(pairwise("abc")))            # [('a', 'b'), ('b', 'c')]

# groupby 相邻分组 (保持相邻语义)
print([(k, list(g)) for k, g in groupby([1, 1, 2, 2, 3, 1])])
print([(k, list(g)) for k, g in groupby("aabbbc")])
print([(k, list(g)) for k, g in groupby([])])

# groupby 带 key
print([(k, list(g)) for k, g in groupby([1, 2, 3, 4, 5], lambda x: x % 2)])

# starmap 解包调用
print(list(starmap(lambda a, b: a + b, [(1, 2), (3, 4)])))          # [3, 7]
print(list(starmap(lambda a, b: a * b, [(1, 2), (3, 4), (5, 6)])))   # [2, 12, 30]
print(list(starmap(max, [(1, 5), (3, 2)])))                          # [5, 3]
print(list(starmap(lambda a, b: a - b, [])))                         # []

# 组合使用: 前缀和与相邻对
print(list(pairwise(accumulate([1, 2, 3, 4]))))   # [(1, 3), (3, 6), (6, 10)]

print("done")
