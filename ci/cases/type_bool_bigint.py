# 职责: bool 与大整数比较/相等, bool 幂与移位边界
# 比对: same_output

# bool 与大数比较/相等此前直接读 int64 快路径 (大数 value 恒 0)
# 改为经大数比较分派: True < 10**100 为真, False == 10**100 为假
print(True < 10 ** 100)
print(True <= 10 ** 100)
print(False == 10 ** 100)
print(True >= 10 ** 100)
print(10 ** 100 > False)
print(10 ** 100 == True)
print(False < 10 ** 100)
print(True > -(10 ** 100))
print(10 ** 100 == True, 10 ** 100 == False)
print(True == 1, False == 0)

# bool 与等值快整数保持原语义 (边界: 大数分派不破坏小整数)
print(True == 1, True < 2, True > 0, True <= 1)
print(False == 0, False < 1, False >= 0)

# bool 幂的边界 (|底数| <= 1 时大数指数结果平凡)
print(True ** (10 ** 100))
print(False ** (10 ** 100))
print(True ** (-(10 ** 100)))
print(True ** 0, False ** 0, True ** 1, False ** 1)
print(True ** 2.5, False ** 2.5)

# False 的负次幂报 ZeroDivisionError (此前静默 inf)
try:
    print(False ** -1)
except ZeroDivisionError as e:
    print("ZDE", str(e))

try:
    print(False ** -1.5)
except ZeroDivisionError as e:
    print("ZDE", str(e))

# bool 移位: True << 大数出大数, True >> 64 恒 0 (宿主位移回绕)
print(True << 70)
print(True << 63)
print(True << 1)
print(True >> 64)
print(True >> 70)
print(False << 10 ** 100)
print(False >> 10 ** 100)
print(True << 0, True >> 0)

# bool 负移位报 ValueError
try:
    print(True << -1)
except ValueError as e:
    print("VE", str(e))

# bool // / % 对浮点零的文案 (CPython: float floor division by zero / float modulo)
try:
    print(True // 0.0)
except ZeroDivisionError as e:
    print("ZDE", str(e))

try:
    print(True % 0.0)
except ZeroDivisionError as e:
    print("ZDE", str(e))

# bool 位运算保持 bool 型 (CPython: True & True is True)
print(True & True, True | False, True ^ True, False & True)
print(True & 3, True | 2, True ^ 1, ~True)
