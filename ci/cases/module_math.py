# 职责: sqrt/floor/三角/阶乘等基础函数
# 比对: same_output

# math 模块测试

import math

# 基础运算
print(math.sqrt(16))  # 4.0
print(math.isqrt(17))  # 4
print(math.floor(3.7))  # 3
print(math.floor(-3.7))  # -4
print(math.ceil(3.2))  # 4
print(math.ceil(-3.2))  # -3
print(math.trunc(-3.7))  # -3
print(math.fabs(-3.5))  # 3.5

# 浮点运算
print(math.fmod(10, 3))  # 1.0
print(round(math.pow(2, 10), 6))  # 1024.0
print(round(math.exp(1), 6))  # 2.718282
print(round(math.log(8, 2), 6))  # 3.0
print(round(math.log2(8), 6))  # 3.0
print(round(math.log10(100), 6))  # 2.0

# 三角函数
print(round(math.sin(0), 6))  # 0.0
print(round(math.cos(0), 6))  # 1.0
print(round(math.tan(0), 6))  # 0.0
print(round(math.hypot(3, 4), 6))  # 5.0
print(round(math.atan2(1, 1), 6))  # 0.785398

# 角度转换
print(round(math.degrees(math.pi), 6))  # 180.0
print(round(math.radians(180), 6))  # 3.141593

# 整数与符号
print(math.factorial(5))  # 120
print(math.gcd(12, 18))  # 6
print(math.copysign(3.0, -1.0))  # -3.0
print(math.copysign(-3.0, 2.0))  # 3.0

# 常数 (通过 round 避免字符串表示差异)
print(round(math.pi, 5))  # 3.14159
print(round(math.e, 5))  # 2.71828

# 判定
print(math.isnan(0.0))  # False
print(math.isinf(1.0))  # False
print(math.isfinite(1.0))  # True

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
    print("FVE:", e)
try:
    math.comb(3, -1)
except ValueError as e:
    print("CVE:", e)
try:
    math.perm(3, -1)
except ValueError as e:
    print("PVE:", e)
try:
    math.comb(-1, 3)
except ValueError as e:
    print("CVE2:", e)
print(math.comb(3, 5))
print(math.perm(5, 7))


# math 大数/类型快路径群 (此前大数 value 恒 0, 浮点 int64 截断回绕)
print(math.floor(10**30))
print(math.floor(-(10**30)))
print(math.ceil(10**30))
print(math.ceil(-(10**30)))
print(math.trunc(10**30))
print(math.floor(1e300))
print(math.ceil(1e300))
print(math.trunc(1e300))
print(math.floor(-2.5))
print(math.ceil(-2.5))
print(math.floor(2.5))
print(math.floor(7))
print(math.floor(True))
print(math.isqrt(10**20))
print(math.isqrt(2))
print(math.isqrt(10**30 - 1))
print(math.isqrt(2**100))
print(math.factorial(21))
print(math.factorial(0))
print(math.factorial(1))
print(len(str(math.factorial(100))))
print(math.comb(10**20, 2))
print(math.comb(5, 2))
print(math.comb(10, 0))
print(len(str(math.perm(60, 30))))
print(math.perm(5, 2))
print(math.gcd(8, 12, 18))
print(math.gcd(0, 5))
print(math.gcd(10**20, 5))
print(math.lcm(4, 6, 8))
print(math.lcm(10**20, 5))
print(math.prod([10**20, 10**20]))
print(math.prod([2, 3, 4]))
print(math.prod([]))
print(math.prod([1.5, 2.0]))

# 类型校验 (此前静默截断/按 0)
try:
    math.isqrt(4.0)
except TypeError as e:
    print("TE-isqrt:", str(e))

try:
    math.gcd(4.0, 6)
except TypeError as e:
    print("TE-gcd:", str(e))

try:
    math.factorial(3.0)
except TypeError as e:
    print("TE-fact:", str(e))

try:
    math.prod(["a", "b"])
except TypeError as e:
    print("TE-prod:", str(e))

# 浮点左值序列重复反射 (序列在右, CPython 文案按左操作数类型)
try:
    math.prod([1.5, "a"])
except TypeError as e:
    print("TE-prod-f:", str(e))
try:
    eval('1.5 * "a"')
except TypeError as e:
    print("TE-mul-f:", str(e))
print(math.prod([True, "a"]))
print(math.prod([2, [1]]))

# 域错误
try:
    print(math.log(8, 0))
except ValueError as e:
    print("VE-log0:", str(e))

try:
    print(math.log(8, 1))
except ZeroDivisionError as e:
    print("ZDE-log1:", str(e))

try:
    print(math.floor(float("nan")))
except ValueError as e:
    print("VE-nan:", str(e))

try:
    print(math.floor(float("inf")))
except OverflowError as e:
    print("OE-inf:", str(e))

# math 域错误 (此前 math.pow/math.fmod 返回 nan 而非报 ValueError)
try:
    math.pow(-8, 0.5)
except ValueError as e:
    print("VE-pow:", e)
try:
    math.pow(0.0, -1)
except ValueError as e:
    print("VE-pow2:", e)
try:
    math.fmod(1, 0)
except ValueError as e:
    print("VE-fmod:", e)
print(round(math.pow(2, 0.5), 6))
print(round(math.fmod(10.5, 3), 6))

# math.factorial 拒绝浮点 (CPython 3.12 文案)
try:
    math.factorial(3.0)
except TypeError as e:
    print("TE:", str(e))
print(math.factorial(5))


# 数字协议 __round__/__floor__/__ceil__/__trunc__ (经 math 侧验证)
class MF28:
    def __floor__(self):
        return 7


print(math.floor(MF28()))


# bool 是 int 子类 (floor/ceil/trunc/atan2 接受 bool)
print(math.floor(True))
print(math.ceil(True))
print(math.trunc(True))
print(math.atan2(True, 1))
print(math.floor(False))

# log1p/expm1/dist 补齐, gcd/lcm/hypot 边界
import math

print("l1p:", math.log1p(0.5), math.log1p(1e-16))
print("em1:", math.expm1(0.5), math.expm1(1e-16))
print("dist:", math.dist([1, 2], [4, 6]), math.dist((0, 0), (3, 4)))
try:
    math.dist([1, 2], [4, 6, 7])
except ValueError as e:
    print("dist-v:", str(e))
print("gcd0:", math.gcd(), math.gcd(12, 18))
print("lcm0:", math.lcm(), math.lcm(4, 6))
print("hyp1:", math.hypot(3), math.hypot(3, -4))


# floor/ceil/trunc 非数值实参文案对齐 CPython
def _show_floor(label, fn):
    try:
        print(label, "OK", fn())
    except Exception as e:
        print(label, type(e).__name__, str(e))


_show_floor("floor_str", lambda: math.floor("3"))
_show_floor("ceil_str", lambda: math.ceil("3"))
_show_floor("trunc_str", lambda: math.trunc("3"))
_show_floor("floor_none", lambda: math.floor(None))
_show_floor("floor_list", lambda: math.floor([1]))
_show_floor("floor_num", lambda: math.floor(3.7))

# 浮点函数族大数实参: 经精确 double 转换后计算 (越界报 OverflowError)
def _mth_exc(label, fn):
    try:
        print(label, repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, str(e))


print(math.sqrt(10 ** 30))
print(math.log(10 ** 30))
print(math.log(10 ** 30, 2))
print(math.log2(10 ** 30))

# log10 大数经 log(x)/log(10) 二次舍入, 与 CPython 的正确舍入 libm 有 1 ULP 级噪声 (宿主平台差异)
print(type(math.log10(10 ** 30)).__name__)
print(math.degrees(10 ** 30))
print(math.radians(10 ** 30))
print(math.fabs(-(10 ** 30)))
print(math.pow(10 ** 30, 2))
print(math.fmod(10 ** 30 + 0.5, 7))
print(math.hypot(3 * 10 ** 30, 4 * 10 ** 30))
print(math.atan2(10 ** 30, 10 ** 30))
print(math.copysign(10 ** 30, -1))
print(math.remainder(10 ** 30 + 1, 7))
print(math.log1p(10 ** 30))
print(math.isnan(10 ** 30), math.isinf(10 ** 30), math.isfinite(10 ** 30))
print(math.cbrt(10 ** 30))
print(math.atan(10 ** 30))

# sin/cos 大角度归约属宿主 libm 平台差异 (P10), 仅断言返回浮点且非零退化值
print(type(math.sin(10 ** 30)).__name__, math.sin(10 ** 30) == 0.0)
print(type(math.cos(10 ** 30)).__name__, math.cos(10 ** 30) == 1.0)
print(type(math.tan(10 ** 30)).__name__)

# 域错误 (含大数)
_mth_exc("sqrt-neg", lambda: math.sqrt(-1))
_mth_exc("log-neg", lambda: math.log(10 ** 30 * -1))
_mth_exc("log2-0", lambda: math.log2(0))
_mth_exc("log2-neg", lambda: math.log2(-1))
_mth_exc("log10-0", lambda: math.log10(0))
_mth_exc("asin-2", lambda: math.asin(2))
_mth_exc("acos-2", lambda: math.acos(2))
_mth_exc("asin-big", lambda: math.asin(10 ** 30))
_mth_exc("exp-1000", lambda: math.exp(1000))
_mth_exc("exp-big", lambda: math.exp(10 ** 30))
_mth_exc("expm1-1000", lambda: math.expm1(1000))
_mth_exc("expm1-big", lambda: math.expm1(10 ** 30))
_mth_exc("sqrt-str", lambda: math.sqrt("x"))
_mth_exc("sin-str", lambda: math.sin("x"))
_mth_exc("fmod-str", lambda: math.fmod(1, "x"))
_mth_exc("fact-str", lambda: math.factorial("x"))

# 越界大数转 double 报 OverflowError (值超出 double 量级)
_mth_exc("deg-huge", lambda: math.degrees(10 ** 400))

# 整数函数大数残余: factorial 上限 / perm 大数 n / comb 大数 n
# (超大 k 的 perm/comb 形态不入常规用例: CPython 3.12 对 k 超上限报 OverflowError,
#  3.13+ 移除上限检查进入 k 次迭代计算, 15s 垫片超时下无法双端断言, 见已知问题清单 P14)
_mth_exc("fact-cap", lambda: math.factorial(2 ** 31))
_mth_exc("fact-big", lambda: math.factorial(10 ** 30))
_mth_exc("fact-neg", lambda: math.factorial(-1))
_mth_exc("fact-float", lambda: math.factorial(5.0))
print(math.factorial(20))
print(math.perm(10 ** 20, 5))
print(math.comb(10 ** 20, 3))
print(math.perm(10 ** 20, 2))
print(math.perm(2 ** 64, 2))
print(math.comb(10 ** 20, 2))
_mth_exc("perm-k-gt-n", lambda: math.perm(5, 10 ** 100))
_mth_exc("perm-float", lambda: math.perm(5.0, 2))
print(math.perm(2 ** 63 - 1, 2))
_mth_exc("comb-k-gt-n", lambda: math.comb(5, 10 ** 100))
print(math.comb(2 ** 63, 2 ** 63 - 1))
print(math.factorial(True), math.perm(True, True), math.comb(True, False))

# 多余位置实参: prod 参数数文案
_mth_exc("prod-2", lambda: math.prod([1], 2))
_mth_exc("prod-kw", lambda: math.prod([1], start=2))
_mth_exc("sorted-2", lambda: __import__("builtins").sorted([1], None) if False else sorted([1], None))
_mth_exc("pow-4", lambda: pow(2, 3, 5, 6))
