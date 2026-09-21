# itertools 模块测试: chain / product / combinations / permutations / islice

from itertools import chain, product, combinations, permutations, islice

# chain 拼接多个可迭代对象
print(list(chain([1, 2], [3], [4, 5])))         # [1, 2, 3, 4, 5]
print(list(chain("ab", "cd")))                  # ['a', 'b', 'c', 'd']
print(list(chain([1], [2], [3])))               # [1, 2, 3]

# product 笛卡尔积
print(list(product([1, 2], [3, 4])))            # [(1, 3), (1, 4), (2, 3), (2, 4)]
print(list(product([1, 2], [3])))               # [(1, 3), (2, 3)]
print(list(product("ab", "12")))                # [('a', '1'), ('a', '2'), ('b', '1'), ('b', '2')]

# combinations 组合
print(list(combinations([1, 2, 3], 2)))         # [(1, 2), (1, 3), (2, 3)]
print(list(combinations([1, 2, 3, 4], 3)))      # [(1, 2, 3), (1, 2, 4), (1, 3, 4), (2, 3, 4)]
print(list(combinations([1, 2, 3], 1)))         # [(1,), (2,), (3,)]

# permutations 排列
print(list(permutations([1, 2], 2)))            # [(1, 2), (2, 1)]
print(list(permutations([1, 2, 3], 2)))         # [(1, 2), (1, 3), (2, 1), (2, 3), (3, 1), (3, 2)]
print(list(permutations([1, 2])))               # [(1, 2), (2, 1)]

# islice 切片
print(list(islice([1, 2, 3, 4, 5], 1, 4)))      # [2, 3, 4]
print(list(islice([1, 2, 3, 4, 5], 3)))         # [1, 2, 3]
print(list(islice([1, 2, 3, 4, 5], 0, 5, 2)))   # [1, 3, 5]
print(list(islice([1, 2, 3], 5)))               # [1, 2, 3]

print("done")
