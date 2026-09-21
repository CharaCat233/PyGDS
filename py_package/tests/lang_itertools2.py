# itertools 扩展测试: repeat / cycle / count / zip_longest / takewhile / dropwhile

from itertools import repeat, cycle, count, zip_longest, takewhile, dropwhile, islice

# repeat 指定次数
print(list(repeat(5, 3)))               # [5, 5, 5]
print(list(repeat("a", 2)))             # ['a', 'a']
print(list(repeat(7, 0)))               # []

# repeat 无限形式 + islice
print(list(islice(repeat(9), 4)))       # [9, 9, 9, 9]

# cycle 循环
print(list(islice(cycle([1, 2, 3]), 5)))   # [1, 2, 3, 1, 2]
print(list(islice(cycle("ab"), 4)))        # ['a', 'b', 'a', 'b']

# count 计数
print(list(islice(count(), 4)))          # [0, 1, 2, 3]
print(list(islice(count(10, 5), 4)))     # [10, 15, 20, 25]
print(list(islice(count(-2), 3)))        # [-2, -1, 0]

# zip_longest 以最长为准
print(list(zip_longest([1, 2], [3], fillvalue=0)))    # [(1, 3), (2, 0)]
print(list(zip_longest([1], [2, 3], [4, 5, 6])))      # [(1, 2, 4), (None, 3, 5), (None, None, 6)]
print(list(zip_longest("ab", "cde", fillvalue="?")))  # [('a', 'c'), ('b', 'd'), ('?', 'e')]

# takewhile 取开头满足条件
print(list(takewhile(lambda x: x < 4, [1, 2, 5, 3, 4])))  # [1, 2]
print(list(takewhile(lambda x: x % 2 == 0, [2, 4, 1, 6]))) # [2, 4]
print(list(takewhile(lambda x: x > 0, [])))                 # []

# dropwhile 丢弃开头满足条件
print(list(dropwhile(lambda x: x < 3, [1, 2, 3, 4, 1])))   # [3, 4, 1]
print(list(dropwhile(lambda x: x == "a", ["a", "a", "b"]))) # ['b']
print(list(dropwhile(lambda x: x < 0, [1, 2, 3])))          # [1, 2, 3]

print("done")
