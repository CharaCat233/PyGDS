# random 模块补全测试: choices / gauss
# 注意: PyGDS 使用内置 xorshift32 PRNG, 数值序列与 CPython 不同,
# 因此只测试与具体随机值无关的结构性行为

import random

random.seed(7)

# choices 默认 k=1
c = random.choices([1, 2, 3])
print(len(c))                  # 1
print(c[0] in [1, 2, 3])       # True

# choices 指定 k
c2 = random.choices(["a", "b", "c"], k=5)
print(len(c2))                 # 5
print(all(x in ["a", "b", "c"] for x in c2))    # True

# choices 位置参数形式 (weights 可位置传入)
print(random.choices([1, 2, 3], [0, 0, 1], k=2))           # [3, 3]
print(len(random.choices([1, 2, 3], [1, 1, 1], k=4)))      # 4

# choices 权重: 单元素权重必中
print(random.choices([1, 2, 3], weights=[0, 0, 1], k=3))   # [3, 3, 3]
print(random.choices([1, 2], weights=[1, 0], k=4))         # [1, 1, 1, 1]

# choices 有放回抽样 (可重复)
print(random.choices([1], k=3))                            # [1, 1, 1]
print(len(random.choices([1, 2], k=10)))                   # 10

# choices 返回列表
print(isinstance(random.choices([1, 2], k=2), list))       # True

# gauss 基本结构: 落在 mu ± 6 sigma 内且为 float
random.seed(11)
vals = [random.gauss(0, 1) for _ in range(20)]
print(len(vals))                                 # 20
print(all(-6 < v < 6 for v in vals))             # True
print(all(isinstance(v, float) for v in vals))   # True

# gauss 参数生效 (mu 平移 / sigma 缩放)
random.seed(11)
centered = [random.gauss(100, 0.5) for _ in range(10)]
print(all(95 < v < 105 for v in centered))       # True

# gauss 默认参数
random.seed(3)
print(isinstance(random.gauss(), float))         # True

# gauss 与 seed 可复现性
random.seed(42)
g1 = random.gauss(0, 1)
random.seed(42)
g2 = random.gauss(0, 1)
print(g1 == g2)                                  # True

# choices 参数错误
try:
    random.choices([], k=1)
except IndexError:
    print("caught IndexError")                   # caught IndexError

try:
    random.choices([1, 2], weights=[1], k=1)
except ValueError:
    print("caught ValueError")                   # caught ValueError

try:
    random.choices([1, 2], weights=[0, 0], k=1)
except ValueError:
    print("caught ValueError")                   # caught ValueError

print("done")
