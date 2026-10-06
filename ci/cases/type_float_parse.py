# duty: 浮点字符串解析的正确舍入: 难例字面量 / float() 语法校验与下划线 / 次规格数与 inf 边界 / repr 最短往返
# 比对: same_output
# 锚定: CPython 3.12
import math

# 难例字面量 (字面量解析路径)
print(9007199254740993.0)
print(1e23)
print(5e-324)
print(2.2250738585072014e-308)
print(1.7976931348623157e308)
print(1.0 / 0.9999999999999999)
print(0.1 + 0.2)
print(2.675)

# float() 字符串解析 (正确舍入) 与 repr 往返
vals = [
    "0.1", "3.14159265358979", "9007199254740993", "1e-324", "2.5e-324", "1e-320",
    "2.2250738585072014e-308", "1.7976931348623157e308", "1e23", "1e400", "1e-400",
    "123456789012345678901234567890", "3.0000000000000001e5", "0.500000000000000166533453693773481063544750213623046875",
    "1_000.5", "1e1_0", "0.5e-323", "1.", ".5", "-0.0", "+3.5",
]
for s in vals:
    v = float(s)
    print(repr(v), float(repr(v)) == v)

# 边界: inf / nan / 零符号
print(float("inf"), float("-inf"), float("Infinity") == math.inf)
print(math.isnan(float("nan")), math.copysign(1.0, float("-0.0")) < 0)
print(math.copysign(1.0, float("0.0")) > 0, float("1e-324") == 0.0)

# 语法错误 (CPython 同文案)
bad = ["1e", ".", "1e5x", "1._5", "_1", "1_", "1_e5", "e5", ""]
for s in bad:
    try:
        float(s)
        print("NO-RAISE", repr(s))
    except ValueError as e:
        print("VE", e)

# format 规格的舍入回转
print("{:.2}".format(2.675), "{:.3}".format(1.0009), "{:.17g}".format(0.1))
