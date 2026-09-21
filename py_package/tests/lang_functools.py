# functools 模块测试: reduce / partial

from functools import reduce, partial

# reduce 基础 (无初始值)
print(reduce(lambda a, b: a + b, [1, 2, 3, 4]))   # 10
print(reduce(lambda a, b: a * b, [1, 2, 3, 4]))   # 24
print(reduce(lambda a, b: max(a, b), [3, 1, 4]))  # 4

# reduce 带初始值
print(reduce(lambda a, b: a + b, [1, 2, 3], 10))  # 16
print(reduce(lambda a, b: a + b, [], 5))          # 5

# reduce 单元素
print(reduce(lambda a, b: a + b, [7]))            # 7

# reduce 拼接字符串
print(reduce(lambda a, b: a + b, ["a", "b", "c"]))  # abc

# partial 偏函数
def add(a, b, c=0):
    return a + b + c

add5 = partial(add, 5)
print(add5(10))              # 15 (5 + 10)
print(add5(10, 2))           # 17 (5 + 10 + 2)

add5c1 = partial(add, 5, c=1)
print(add5c1(3))             # 9 (5 + 3 + 1)

# partial 绑定全部参数
add_all = partial(add, 1, 2, 3)
print(add_all())             # 6

# partial 与 lambda
double = partial(lambda x: x * 2)
print(double(21))            # 42

# callable 判定
print(callable(add5))        # True

print("done")
