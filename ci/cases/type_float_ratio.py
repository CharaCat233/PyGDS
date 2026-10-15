# 职责: float.as_integer_ratio 大数缩放与 is_integer 边界
# 比对: same_output

# as_integer_ratio 此前用 int64 连乘 2 缩放, |exp| 超界回绕
# 改为大数承载: (2.0**63).as_integer_ratio() 此前回绕 INT64_MIN
print((2.0**63).as_integer_ratio())
print((-(2.0**63)).as_integer_ratio())
print((2.0**64).as_integer_ratio())
print((1.5).as_integer_ratio())
print((-1.5).as_integer_ratio())
print((0.5).as_integer_ratio())
print((0.1).as_integer_ratio())
print((2.0**10).as_integer_ratio())
print((5e-324).as_integer_ratio())
print((10.0**30).as_integer_ratio())

# 零值与负零 (CPython: 0.0 与 -0.0 均为 (0, 1))
print((0.0).as_integer_ratio())
print((-0.0).as_integer_ratio())
print((-0.0).as_integer_ratio() == (0.0).as_integer_ratio())

# NaN / inf 的报错类型 (NaN 为 ValueError, inf 为 OverflowError)
try:
    print(float("nan").as_integer_ratio())
except ValueError as e:
    print("VE", str(e))

try:
    print(float("inf").as_integer_ratio())
except OverflowError as e:
    print("OE", str(e))

try:
    print((-float("inf")).as_integer_ratio())
except OverflowError as e:
    print("OE", str(e))

# is_integer 对 inf 此前返回 True (仅排除 NaN), 改为 ±inf 均 False
print(float("inf").is_integer())
print((-float("inf")).is_integer())
print(float("nan").is_integer())
print((2.0).is_integer())
print((2.5).is_integer())
print((0.0).is_integer())
print((1e300).is_integer())
print((-3.0).is_integer())
