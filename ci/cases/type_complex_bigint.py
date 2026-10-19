# 职责: complex 与大整数混算/比较, 除法中间量溢出
# 比对: same_output

# complex 与大整数混算此前把大数当 0 (value 恒 0 快路径)
# 实参改为经 53 位舍入转 double
print(0j == 10 ** 100)
print(10 ** 100 == 1e100 + 0j)
print(10 ** 100 * 1j)
print(10 ** 100 + 1j)
print(10 ** 100 - 1j)
print(10 ** 100 / 2j)
print((2 ** 53 + 1) + 1j)
print(1j + 2 ** 53)
print((10 ** 30) * (1 + 1j))

# complex 与快整数保持原语义
print(0j == 0, 1j == 1, (1 + 0j) == 1)
print(3 * 1j, 5 + 2j, 10 / 2j)

# complex 构造对大数实参: 越界报 OverflowError (此前按 0 构造)
try:
    print(complex(10 ** 400))
except OverflowError as e:
    print("OE", str(e))

# 越界混算: 大数实参转 double 越界报 OverflowError
try:
    print((10 ** 400) + 1j)
except OverflowError as e:
    print("OE", str(e))

# complex 除法中间量溢出 (平方和公式在 1e300/1e200 量级溢出)
# 改为 Smith 缩放除法
print(complex(1e300) / complex(1e200))
print(complex(1e300) / complex(1e200, 1e200))
print(complex(1e-300) / complex(1e-200))
print(complex(1e200, 1e200) / complex(1e200, -1e200))
print((1 + 2j) / (3 + 4j))
print(1j / 1j)
print(complex(1e200) / 2)

# complex 除零
try:
    print(1j / 0j)
except ZeroDivisionError as e:
    print("ZDE", str(e))

try:
    print(1j / 0)
except ZeroDivisionError as e:
    print("ZDE", str(e))

# 负底数分数次幂 (此前返回 nan, 应升格 complex 主值分支)
# 虚部与 CPython 一致; 实部为 Godot libm 的 π/2 邻域 cos 噪声底 (平台差异), 取 round 后比对
r1 = (-2.0) ** 0.5
print(type(r1).__name__)
print(round(abs(r1), 10))
print(round(r1.imag, 10))
r2 = (-2) ** 0.5
print(type(r2).__name__)
print(round(abs(r2), 10))
print(round(r2.imag, 10))
# round(complex) 双端均报 TypeError (complex 无 __round__), 仅断言异常类
try:
    round((-8) ** (1 / 3), 10)
except TypeError as e:
    print("TE-round:", e)
print((-2.0) ** 2.0)
print((-2.0) ** 3)
# 整值指数的负底数仍是实数, 分数指数升格 complex
r3 = (-4.0) ** 1.5
print(type(r3).__name__)
print(round(abs(r3), 10))
print(round(r3.imag, 10))

# 复数幂上溢: 结果分量出现 ±inf 报 OverflowError (NaN 传播 / nan 化 / 下溢零不误报)
def _pw(label, fn):
    try:
        print(label, fn())
    except Exception as e:
        print(label, type(e).__name__, str(e))

_pw("pw1", lambda: (2 + 3j) ** (10 ** 80))
_pw("pw2", lambda: (10 + 0j) ** 400.0)
_pw("pw3", lambda: (1e200 + 0j) ** 2)
_pw("pw4", lambda: (1e300 + 2j) ** 2)
_pw("pw5", lambda: (float("inf") + 0j) ** 0.5)
_pw("pw6", lambda: (1e200 + 1e200j) ** 2.5)
_pw("pw7", lambda: (1e300 + 0j) ** 1.5)

# NaN 传播与 inf 基底 nan 化: 不报错
_pw("pw8", lambda: (float("nan") + 0j) ** 2)
_pw("pw9", lambda: (float("nan") + 0j) ** 2.5)
_pw("pw10", lambda: (float("inf") + 0j) ** 2)
_pw("pw11", lambda: (float("inf") + 1j) ** 2)
_pw("pw12", lambda: (1e200 + 0j) ** 100)
_pw("pw13", lambda: (1e200 + 1j) ** 100)

# 下溢零不误报
_pw("pw14", lambda: (1e-200 + 0j) ** 100)

# 零基底: 正实指数返回 0j, 零指数返回 1, 负指数报零底数负幂
_pw("pw15", lambda: 0j ** 0.5)
_pw("pw16", lambda: 0j ** 2.5)
_pw("pw17", lambda: 0j ** 2)
_pw("pw18", lambda: 0j ** 0)
_pw("pw19", lambda: 0j ** (-1))

# 负指数下溢: 商除零按 CPython EDOM 通道报零底数负幂
_pw("pw20", lambda: (1e-200 + 0j) ** -2)
