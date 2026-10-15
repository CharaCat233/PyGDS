# 职责: str % 格式化浮点实参校验与整数精确化
# 比对: same_output

# %d/%x/%o/%c 对浮点实参此前静默截断, %d 对 NaN/inf 回绕 int64

# %x/%X/%o 拒绝浮点 (CPython: an integer is required)
try:
    print("%x" % 1.5)
except TypeError as e:
    print("TE-x:", str(e))

try:
    print("%o" % 1.5)
except TypeError as e:
    print("TE-o:", str(e))

try:
    print("%X" % 2.5)
except TypeError as e:
    print("TE-X:", str(e))

# %c 拒绝浮点
try:
    print("%c" % 1.5)
except TypeError as e:
    print("TE-c:", str(e))

# %d 对 NaN/inf 报错 (此前回绕 int64)
try:
    print("%d" % float("nan"))
except ValueError as e:
    print("VE-nan:", str(e))

try:
    print("%d" % float("inf"))
except OverflowError as e:
    print("OE-inf:", str(e))

try:
    print("%i" % float("-inf"))
except OverflowError as e:
    print("OE-inf:", str(e))

# %d 小整数不再经 float 往返 (2^53 上不失真)
print("%d" % (2**53 + 1))
print("%d" % (2**63 - 1))
print("%d" % 42)
print("%d" % -7)

# 大数 %d 精确
print("%d" % (10**30))
print("%d" % -(10**30))
print("%x" % (2**64))
print("%o" % (2**64))
print("%x" % 255)
print("%o" % 64)

# bool 按 int 参与
print("%d" % True)
print("%x" % True)
print("%d" % False)
print("%o" % False)

# %d 浮点截断正常 (非 NaN/inf)
print("%d" % 3.7)
print("%d" % -3.7)
print("%i" % 2.9)

# %c 整数正常
print("%c" % 65)
print("%c" % 0x4E2D)
try:
    print("%c" % -1)
except OverflowError as e:
    print("OE-c:", str(e))
try:
    print("%c" % 0x110000)
except OverflowError as e:
    print("OE-c2:", str(e))

# % 格式化映射键路径 (此前非映射实参静默返回空串, 缺键静默截断)
# CPython: 命名字段要求映射实参; 缺键报 KeyError
try:
    print("%(a)s" % 5)
except TypeError as e:
    print("TE:", e)
try:
    print("%(a)s" % {"x": 1})
except KeyError as e:
    print("KE:", e)
print("%(a)s and %(b)s" % {"a": 1, "b": 2})
print("%(name)s is %(age)d" % {"name": "Alice", "age": 30})
print("%s and %s" % ("a", "b"))

# 截断形态报错 (此前静默返回部分结果)
try:
    print("abc%" % ())
except ValueError as e:
    print("VE:", e)
try:
    print("%(a" % {})
except ValueError as e:
    print("VE2:", e)
try:
    print("%" % ())
except ValueError as e:
    print("VE3:", e)
print("%s done" % "x")


# %*d 星号宽度/精度 (负宽左对齐, 浮点宽报错)
print("%*d" % (5, 42))
print("%*d" % (-5, 42))
print("%.*f" % (2, 3.14159))
print("%*.*f" % (5, 2, 3.14159))
try:
    "%*d" % (1.5, 42)
except TypeError as e:
    print("TE-star:", str(e))
# 未知转换符报 ValueError (此前静默原样返回)
try:
    "%v" % 1
except ValueError as e:
    print("VE-v:", str(e))
try:
    "%q" % 1
except ValueError as e:
    print("VE-q:", str(e))
print("%d" % 1)
