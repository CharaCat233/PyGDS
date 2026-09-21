# math 扩展测试: comb / perm / prod / lcm

import math

# comb 组合数
print(math.comb(5, 2))          # 10
print(math.comb(5, 5))          # 1
print(math.comb(4, 0))          # 1
print(math.comb(10, 3))         # 120

# perm 排列数
print(math.perm(5, 2))          # 20
print(math.perm(5, 5))          # 120
print(math.perm(4, 0))          # 1
print(math.perm(10, 3))         # 720

# prod 连乘
print(math.prod([2, 3, 4]))        # 24
print(math.prod([2, 3], start=10)) # 60
print(math.prod([]))               # 1
print(math.prod([1, 2, 3], start=0))  # 0

# lcm 最小公倍数
print(math.lcm(4, 6))           # 12
print(math.lcm(6, 8, 12))       # 24
print(math.lcm(7, 5))           # 35
print(math.lcm(0, 5))           # 0

print("done")
