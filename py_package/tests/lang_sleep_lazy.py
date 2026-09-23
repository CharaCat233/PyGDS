# 生成器/推导式内的 sleep 测试 (与 CPython 行为一致)

import time
from itertools import islice

# 推导式元素内含 sleep
print([time.sleep(0) for x in range(3)])

# 推导式条件内含 sleep
print([x for x in [1, 2, 3] if time.sleep(0)])

# 推导式元素内调用含 sleep 的函数
def f(x):
    time.sleep(0)
    return x * 10


print([f(x) for x in [1, 2, 3]])

# 生成器表达式元素内含 sleep
print(list(time.sleep(0) for x in range(2)))

# 生成器表达式作为推导式迭代源 (用户例)
print([v for v in (time.sleep(0) for x in range(2))])

# 集合 / 字典 / 元组推导式
def g(x):
    time.sleep(0)
    return x


print({g(x) for x in range(2)})
print({g(x): g(x) * 2 for x in range(2)})
print(tuple(g(x) for x in range(3)))

# 生成器函数体内 sleep
def counter():
    for i in range(3):
        time.sleep(0)
        yield i


print(list(counter()))

# 消费函数与 sleep 的生成器
def gen():
    for i in [3, 1, 2]:
        time.sleep(0)
        yield i


print(sum(gen()))
print(sorted(gen()))
print(min(gen()))
print(max(gen()))
print(any(x > 2 for x in gen()))
print(all(x > 0 for x in gen()))
print(list(enumerate(gen())))
print(list(zip(gen(), "abc")))

# islice 惰性消费
def infinite():
    n = 0
    while True:
        time.sleep(0)
        yield n
        n += 1


print(list(islice(infinite(), 4)))

print("done")
