# 职责: sqrt/floor/三角/阶乘等基础函数
# 比对: same_output

# math 模块测试

import math

# 基础运算
print(math.sqrt(16))          # 4.0
print(math.isqrt(17))         # 4
print(math.floor(3.7))        # 3
print(math.floor(-3.7))       # -4
print(math.ceil(3.2))         # 4
print(math.ceil(-3.2))        # -3
print(math.trunc(-3.7))       # -3
print(math.fabs(-3.5))        # 3.5

# 浮点运算
print(math.fmod(10, 3))       # 1.0
print(math.pow(2, 10))        # 1024.0
print(round(math.exp(1), 6))  # 2.718282
print(round(math.log(8, 2), 6))   # 3.0
print(round(math.log2(8), 6))     # 3.0
print(round(math.log10(100), 6))  # 2.0

# 三角函数
print(round(math.sin(0), 6))  # 0.0
print(round(math.cos(0), 6))  # 1.0
print(round(math.tan(0), 6))  # 0.0
print(round(math.hypot(3, 4), 6))  # 5.0
print(round(math.atan2(1, 1), 6))  # 0.785398

# 角度转换
print(round(math.degrees(math.pi), 6))  # 180.0
print(round(math.radians(180), 6))      # 3.141593

# 整数与符号
print(math.factorial(5))      # 120
print(math.gcd(12, 18))       # 6
print(math.copysign(3.0, -1.0))  # -3.0
print(math.copysign(-3.0, 2.0))  # 3.0

# 常数 (通过 round 避免字符串表示差异)
print(round(math.pi, 5))      # 3.14159
print(round(math.e, 5))       # 2.71828

# 判定
print(math.isnan(0.0))        # False
print(math.isinf(1.0))        # False
print(math.isfinite(1.0))     # True

# 域错误路径
print(math.floor(2.7), math.sqrt(16))
try:
    math.sqrt(-1)
except ValueError as e:
    print("VE:", e)
try:
    math.log(0)
except ValueError as e:
    print("LOG:", e)

try:
    math.factorial(-1)
except ValueError as e:
    print("FVE:", type(e).__name__)
try:
    math.comb(3, -1)
except ValueError as e:
    print("CVE:", type(e).__name__)
try:
    math.perm(3, -1)
except ValueError as e:
    print("PVE:", type(e).__name__)

print("done")