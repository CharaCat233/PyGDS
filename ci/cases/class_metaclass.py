# 职责: 自定义元类机制 (I1-38): metaclass= 的 __new__/__init__ 建类与 ns 修改回填 / __call__ 定制实例化 / 元类方法与属性查找 / 实例不穿透元类属性 / 双元类 conflict / __prepare__ 调用 / 隐式 __module__ 与 __qualname__
# 比对: same_output
# 锚定: CPython 3.12
def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


class Meta(type):
    def __new__(mcls, name, bases, ns, **kw):
        print("meta new", name)
        ns["added"] = 42
        return super().__new__(mcls, name, bases, ns, **kw)

    def __init__(cls, name, bases, ns, **kw):
        print("meta init", name)
        super().__init__(name, bases, ns, **kw)


class C(metaclass=Meta):
    x = 1


t("C.added", lambda: C.added)
t("C.x", lambda: C.x)
t("type_C", lambda: type(C).__name__)
t("isinstance_C", lambda: isinstance(C(), C))


class Meta2(type):
    def __call__(cls, *a, **k):
        print("meta call", a)
        return "custom"


class X(metaclass=Meta2):
    pass


t("call_custom", lambda: X(1, 2))


class MA(type):
    def m_method(cls):
        return "meta method"
    attr = "meta attr"


class Z(metaclass=MA):
    pass


t("meta_method", lambda: Z.m_method())
t("meta_attr", lambda: Z.attr)
t("inst_no_meta_attr", lambda: hasattr(Z(), "attr"))


class M1(type):
    pass


class M2(type):
    pass


class B1(metaclass=M1):
    pass


class B2(metaclass=M2):
    pass


t("conflict", lambda: None)
try:
    class CC(B1, B2):
        pass
except TypeError as e:
    print("conflict TypeError :", e)


class PC(type):
    def __new__(mcls, name, bases, ns, **kw):
        print("ns keys", sorted(ns.keys()))
        return super().__new__(mcls, name, bases, ns, **kw)


class G(metaclass=PC):
    y = 2
    def m(self):
        pass


t("G.y", lambda: G.y)
t("G.m", lambda: callable(G.m))


class MI(type):
    pass


class Mi(metaclass=MI):
    def __init__(self, v):
        self.v = v


t("普通实例化", lambda: Mi(5).v)
t("Mi type", lambda: type(Mi).__name__)
