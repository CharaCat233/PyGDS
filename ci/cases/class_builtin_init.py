# 职责: 内建类型子类的用户 __init__ 与构造分层 (I1-73): 可变子类 __new__ 纯分配由 init 填充, 不可变子类 __new__ 严格消费实参后 init 仍调用, init 签名错误带限定名, 子类实例字典与 set/deque 子类 repr 带类名, bool/range/slice/memoryview/NoneType 不可继承, init 内挂起重放副作用不重复
# 比对: same_output
# 锚定: CPython 3.12
from collections import deque


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


class L2(list):
    def __init__(self, x=0):
        self.x = x


t("L2_default", lambda: (list(L2()), L2().x))
t("L2_int", lambda: (list(L2(5)), L2(5).x))
t("L2_iter", lambda: (list(L2([1, 2])), L2([1, 2]).x))
t("L2_kw", lambda: (list(L2(x=1)), L2(x=1).x))
t("L2_2pos", lambda: L2(1, 2))
t("L2_repr", lambda: repr(L2([1])))
t("L2_eq", lambda: L2([1]) == [1])
t("L2_append", lambda: (lambda v: (v.append(1), list(v), v.x))(L2()))
t("L2_setattr", lambda: (lambda v: (setattr(v, "y", 2), v.y))(L2()))
t("L2_dict", lambda: L2(3).__dict__)


class L3(list):
    def __init__(self, a, b):
        pass


t("L3_missing", lambda: L3([1]))
t("L3_kw", lambda: L3([1], b=2))
t("L3_extra", lambda: L3([1], 2, 3))


class L4(list):
    def __init__(self):
        self.t = 1


t("L4_1pos", lambda: L4(1))


class L9(list):
    pass


t("L9_repr", lambda: repr(L9([1])))
t("L9_eq", lambda: L9([1]) == [1])
t("L9_kw", lambda: L9([1], bogus=2))
t("L9_2pos", lambda: L9([1], 2))
t("L9_setattr", lambda: (lambda v: (setattr(v, "z", 1), v.z))(L9()))


class L5(list):
    def __init__(self, x, **k):
        self.k = k


t("L5_kw", lambda: (list(L5([1], bogus=2)), L5([1], bogus=2).k))
t("L5_zero", lambda: L5())


class LS(str):
    def __init__(self, *a):
        self.tag = 9


t("LS_init", lambda: (LS("ab"), LS("ab").tag))
t("LS_upper", lambda: LS("ab").upper())
t("LS_eq", lambda: LS("ab") == "ab")
t("LS_hash", lambda: hash(LS("ab")) == hash("ab"))


class SS(str):
    def __init__(self, a, b):
        pass


t("SS_1pos", lambda: SS("x"))


class DS9(str):
    pass


t("DS9_kw", lambda: DS9("ab", bogus=1))
t("DS9_2pos", lambda: DS9("ab", 2))


class T2(tuple):
    def __init__(self, x):
        self.tag = 3


t("T2", lambda: (T2([1, 2]), T2([1, 2]).tag))
t("T2_missing", lambda: T2())


class T9(tuple):
    pass


t("T9_repr", lambda: repr(T9([1, 2])))


class I2(int):
    def __init__(self, x):
        self.tag = 7


t("I2", lambda: (I2(5), I2(5).tag, int(I2(5)) + 1))


class IS(int):
    def __init__(self, x):
        self.t = x


t("IS_2pos", lambda: IS(5, 6))
t("IS_kw", lambda: IS(5, y=1))


class DI2(int):
    pass


t("DI2_kw", lambda: DI2(5, bogus=1))
t("DI2_2pos", lambda: DI2(5, 2))


class F2(float):
    def __init__(self, x):
        self.tag = 1


t("F2", lambda: (F2(1.5), F2(1.5).tag))


class S9c(set):
    pass


t("S9c_repr", lambda: repr(S9c([1])))


class S9b(set):
    def __init__(self, *a, **k):
        self.tag = 1


t("S9b", lambda: (list(S9b([1])), S9b([1]).tag))
t("S9b_repr", lambda: repr(S9b([1])))


class D9(deque):
    pass


t("D9_repr", lambda: repr(D9([1, 2], maxlen=2)))
t("D9_eq", lambda: D9([1]) == deque([1]))
t("D9_kw", lambda: D9([1], bogus=2))
t("D9_2pos", lambda: D9([1], 2))
t("D9_iter", lambda: list(deque(iter([1, 2]))))


class D4b(deque):
    def __init__(self, *a, **k):
        super().__init__(*a, **k)
        self.tag = 9


t("D4b_super", lambda: (list(D4b([1, 2], maxlen=1)), D4b([1, 2], maxlen=1).tag))


class D5b(deque):
    def __init__(self, *a, **k):
        self.tag = 1


t("D5b_nofwd", lambda: (list(D5b([1, 2], maxlen=1)), D5b([1, 2], maxlen=1).tag))
t("D5b_maxlen_attr", lambda: D5b([1], maxlen=3).maxlen)

# 不可继承内建类型 (CPython tp_flags 无 BASETYPE)
def try_base(name):
    try:
        if name == "bool":
            class XB(bool):
                pass
        elif name == "range":
            class XR(range):
                pass
        elif name == "slice":
            class XS(slice):
                pass
        elif name == "memoryview":
            class XM(memoryview):
                pass
        else:
            class XN(type(None)):
                pass
        return "ok"
    except TypeError as e:
        return str(e)


t("nobase_bool", lambda: try_base("bool"))
t("nobase_range", lambda: try_base("range"))
t("nobase_slice", lambda: try_base("slice"))
t("nobase_memoryview", lambda: try_base("memoryview"))
t("nobase_nonetype", lambda: try_base("NoneType"))

# init 内挂起: 重放副作用不重复, 属性写入不丢
import time


class L2s(list):
    def __init__(self, x):
        print("init", x)
        time.sleep(0)
        self.x = x


v = L2s(3)
print(list(v), v.x)


def g():
    for i in [1, 2]:
        time.sleep(0)
        yield i


class D2s(list):
    def __init__(self, it):
        self.n = 0
        for item in it:
            self.n += 1
        time.sleep(0)


d = D2s(g())
print(d.n)

# 生成器构造与 genexp 挂起重放 (构造器可迭代实参经 __new__ 挂起)
def gs(v):
    time.sleep(0)
    yield v * 2


print(list(gs(1)))
print(list(gs(2)))
print(tuple(gs(3)))
print(list(deque(gs(4))))


# __iter__ 返回非迭代对象的严格文案 (I2-43): for/iter/推导式/list/星形/消费器
# 双端同文案, 重放轮宽松回退
class BadIter:
    def __iter__(self):
        return 42


class OkIter:
    def __iter__(self):
        return iter([1, 2])


t("bad_for", lambda: [x for x in BadIter()])
t("bad_iter", lambda: list(iter(BadIter())))
t("bad_comp", lambda: [y for y in BadIter()])
t("bad_list", lambda: list(BadIter()))
t("bad_star", lambda: [*BadIter()])
t("bad_in", lambda: 1 in BadIter())
t("ok_iter", lambda: [x for x in OkIter()])
t("bad_sorted", lambda: sorted(BadIter()))
t("bad_genexp", lambda: list(x for x in BadIter()))

# 挂起消费下的 __iter__ 再入 (重放轮宽松回退不循环)
def g():
    for i in [1, 2, 3]:
        time.sleep(0)
        yield i


class W:
    def __iter__(self):
        return iter(g())


try:
    for x in BadIter():
        pass
except TypeError as e:
    print("bad:", e)
