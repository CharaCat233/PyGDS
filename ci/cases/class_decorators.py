# 职责: 内建方法装饰器与任意装饰器叠加包装
# 比对: same_output

# 内建装饰器与任意装饰器组合的包装语义 (P2-17)
def wrap(f):
    def inner(*a, **k):
        return ("wrapped", f(*a, **k))
    return inner

class C:
    @staticmethod
    @wrap
    def f(x):
        return x + 1
    @classmethod
    @wrap
    def g(cls, x):
        return (cls.__name__, x)
    @property
    @wrap
    def p(self):
        return "prop"
    @staticmethod
    def plain(x):
        return x - 1
    @classmethod
    def cplain(cls, x):
        return (cls.__name__, x + 1)

class D(C):
    pass

print(C.f(1))
print(C().f(2))
print(C.g(3))
print(C().g(4))
c = C()
print(c.p)
print(C.plain(7))
print(c.plain(8))
print(C.cplain(9))
print(c.cplain(10))
print(D.f(11))
print(D.g(12))
print(callable(C.f))
print(type(C.f).__name__)
print(type(C.g).__name__)
print(C.f.__name__)

# 反序组合: 内建形式在最内层, 包装函数直接收到内建包装对象
class R:
    @wrap
    @staticmethod
    def h(x):
        return x * 2
    @wrap
    @property
    def pp(self):
        return "p"

print(R.h(5))
try:
    R().h(6)
except TypeError:
    print("TypeError-h")
r = R()
print(type(r.pp).__name__)
try:
    r.pp()
except TypeError:
    print("TypeError-call")
print("done")
