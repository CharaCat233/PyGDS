# random 模块测试
# 注意: PyGDS 使用内置 xorshift32 PRNG, 数值序列与 CPython 不同,
# 因此只测试与具体随机值无关的结构性行为

import random

# 范围与类型检查 (不依赖具体随机值)
r = random.random()
print(0.0 <= r < 1.0)          # True

n = random.randint(1, 6)
print(1 <= n <= 6)             # True

print(random.randint(3, 3))    # 3 (单值范围)

u = random.uniform(0, 1)
print(0.0 <= u <= 1.0)         # True

x = random.randrange(10)
print(0 <= x < 10)             # True

print(random.choice([7]))      # 7 (单元素)

# seed 可复现性 (同一 seed 产生相同序列)
random.seed(42)
a1 = random.random()
random.seed(42)
a2 = random.random()
print(a1 == a2)                # True

# 连续两次 random 几乎必然不同
random.seed(1)
b1 = random.random()
b2 = random.random()
print(b1 != b2)                # True

# shuffle 保持长度与元素集合
lst = [1, 2, 3, 4]
random.shuffle(lst)
print(len(lst))                # 4
print(sorted(lst))             # [1, 2, 3, 4]

# sample 返回指定数量的不重复元素
s = random.sample(range(20), 5)
print(len(s))                  # 5
print(len(set(s)))             # 5 (元素互不相同)

print("done")
