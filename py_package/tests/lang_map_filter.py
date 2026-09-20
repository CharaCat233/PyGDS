# map / filter 内置函数测试

# map 基础
def double(x):
    return x * 2

print(list(map(double, [1, 2, 3])))          # [2, 4, 6]

# map + lambda
print(list(map(lambda x: x + 1, [1, 2, 3]))) # [2, 3, 4]

# map 类型转换
print(list(map(str, [1, 2, 3])))             # ['1', '2', '3']

# map 多个可迭代对象
print(list(map(lambda a, b: a + b, [1, 2], [10, 20])))  # [11, 22]

# map 字符串方法
print(list(map(lambda s: s.upper(), ["a", "b"])))        # ['A', 'B']

# map 遍历字符串
print(list(map(ord, "ABC")))                 # [65, 66, 67]

# filter 基础
print(list(filter(lambda x: x > 1, [0, 1, 2, 3])))      # [2, 3]

# filter 偶数
print(list(filter(lambda x: x % 2 == 0, [1, 2, 3, 4]))) # [2, 4]

# filter(None, ...) 真值过滤
print(list(filter(None, [0, 1, "", "a", [], [1]])))     # [1, 'a', [1]]

# 命名函数
def is_even(n):
    return n % 2 == 0

print(list(filter(is_even, range(1, 7))))    # [2, 4, 6]

# for 循环中使用 map
for x in map(lambda n: n * 3, [1, 2]):
    print(x)                                 # 3, 6

# 组合使用: 先 filter 再 map
nums = list(range(1, 8))
evens = list(filter(lambda x: x % 2 == 0, nums))
print(list(map(lambda x: x * 10, evens)))    # [20, 40, 60]

print("done")
