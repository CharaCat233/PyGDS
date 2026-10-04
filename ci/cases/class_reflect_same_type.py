# duty: 同类反射运算的跳过规则 (CPython 同类不尝试 __r*__, 跨类型反射与增强赋值文案)
# compare: same_output
# anchor: CPython 3.12

class S:
    def __radd__(self, o):
        return "r"

# CPython 对类型相同的两侧只调用一次槽函数, 槽内反射仅在两侧类型不同时尝试:
# 仅定义 __radd__ 的同类相加直接报 TypeError, 不进入反射
try:
    print("S+S:", S() + S())
except TypeError as e:
    print("S+S TypeError:", e)

# 跨类型反射不受同类约束影响
print("1+S:", 1 + S())
print("True+S:", True + S())

# 增强赋值失败文案用增强形式 (+=), 同类同样不反射
s = S()
try:
    s += 1
except TypeError as e:
    print("s+=1 TypeError:", e)
try:
    print("S+=S:", S() + S())
except TypeError as e:
    print("S+=S TypeError:", e)
s2 = S()
try:
    s2 += S()
except TypeError as e:
    print("s2+= TypeError:", e)

# 子类与基类互运算时类型不同, 反射照常尝试
class Sub(S):
    pass
print("Sub+S:", Sub() + S())
print("S+Sub:", S() + Sub())

# 共同基类的两个子类之间类型不同, 反射照常尝试
class B:
    def __radd__(self, o):
        return "r"
class A(B):
    pass
class C(B):
    pass
print("A+C:", A() + C())
try:
    print("B+B:", B() + B())
except TypeError as e:
    print("B+B TypeError:", e)

# 两侧均定义 __add__ 的同类正常运算不受影响
class N:
    def __add__(self, o):
        return "n"
print("N+N:", N() + N())

# 同类不反射通则覆盖全部 __r*__ 运算 (含 @)
class M:
    def __rmatmul__(self, o):
        return "m"
try:
    print("M@M:", M() @ M())
except TypeError as e:
    print("M@M TypeError:", e)
print("1@M:", 1 @ M())

# 减法与乘法的同类形态同规则
class R:
    def __rsub__(self, o):
        return "rs"
    def __rmul__(self, o):
        return "rm"
try:
    print("R-R:", R() - R())
except TypeError as e:
    print("R-R TypeError:", e)
try:
    print("R*R:", R() * R())
except TypeError as e:
    print("R*R TypeError:", e)
print("1-R:", 1 - R())
print("2*R:", 2 * R())
