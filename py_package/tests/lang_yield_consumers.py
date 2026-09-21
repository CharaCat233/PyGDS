# 生成器函数与消费函数贯通测试

from itertools import islice

def nums():
    for i in range(5):
        yield i

# sum / sorted / min / max / any / all
print(sum(nums()))                      # 10
print(sorted(nums()))                   # [0, 1, 2, 3, 4]
print(min(nums()))                      # 0
print(max(nums()))                      # 4
print(any(x > 3 for x in nums()))       # True
print(all(x < 5 for x in nums()))       # True

# enumerate / zip
print(list(enumerate(nums(), start=1)))  # [(1, 0), (2, 1), (3, 2), (4, 3), (5, 4)]
print(list(zip(nums(), "abc")))          # [(0, 'a'), (1, 'b'), (2, 'c')]

# list / tuple 构造
print(list(nums()))                     # [0, 1, 2, 3, 4]
print(tuple(nums()))                    # (0, 1, 2, 3, 4)

# islice 惰性消费无限生成器
def infinite():
    n = 0
    while True:
        yield n
        n += 1
print(list(islice(infinite(), 5)))      # [0, 1, 2, 3, 4]

# 生成器与生成器表达式混合
def double(x):
    yield x * 2
print([y for x in range(3) for y in double(x)])   # [0, 2, 4]
print(list(x for x in nums() if x % 2 == 0))      # [0, 2, 4]

print("done")
