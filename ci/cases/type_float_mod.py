# 职责: float 取模/整除的双舍入修复与符号语义
# 比对: same_output

# float % 此前用 a - b*floor(a/b), 大数量级下先除后取整双重舍入
# 改为 CPython float_mod: 精确 fmod 后按除数符号校正
print(float(2 ** 60) % 3.0)
print((2 ** 60) % 3.0)
print(float(2 ** 53) % 3.0)
print(float(2 ** 60 + 1) % 3.0)
print(1e20 % 3.0)

# 符号语义: 结果符号随除数 (CPython)
print(-7.5 % 2.0)
print(7.5 % -2.0)
print(-7.5 % -2.0)
print(7.5 % 2.0)
print(-0.5 % 1.0)
print(0.5 % -1.0)

# 整数实参对浮点取模同路径
print((2 ** 60) % 3.0)
print(-(2 ** 60) % 3.0)

# // 的商侧: 先取 Python 语义 mod 再一次舍入 (此前 floor(a/b) 双重舍入)
print(float(2 ** 60) // 3.0)
print((2 ** 60) // 3.0)
print(-7.5 // 2.0)
print(7.5 // -2.0)
print(-0.5 // 1)
print(1e20 // 3.0)
print(-1e20 // 3.0)

# divmod 与 % 的一致性 (CPython: divmod(a,b) == (a//b, a%b))
a, b = 2.0 ** 60, 3.0
q, r = divmod(a, b)
print(q == a // b, r == a % b)
print(divmod(-7.5, 2.0))
print(divmod(7.5, -2.0))

# 整除为负零的形态 (CPython: 商为 -0.0 时保留负零)
print(1.0 // -2.0)
print(-1.0 // 2.0)

# 浮点取模除零报错 (此前 float modulo)
try:
    print(1.0 % 0.0)
except ZeroDivisionError as e:
    print("ZDE", str(e))

try:
    print(1.0 // 0.0)
except ZeroDivisionError as e:
    print("ZDE", str(e))
