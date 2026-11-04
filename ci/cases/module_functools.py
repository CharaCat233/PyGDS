# 职责: reduce 折叠与 partial 偏函数参数绑定
# 比对: same_output

# functools 模块测试: reduce / partial

import functools
from functools import reduce, partial

# reduce 基础 (无初始值)
print(reduce(lambda a, b: a + b, [1, 2, 3, 4]))  # 10
print(reduce(lambda a, b: a * b, [1, 2, 3, 4]))  # 24
print(reduce(lambda a, b: max(a, b), [3, 1, 4]))  # 4

# reduce 带初始值
print(reduce(lambda a, b: a + b, [1, 2, 3], 10))  # 16
print(reduce(lambda a, b: a + b, [], 5))  # 5

# reduce 单元素
print(reduce(lambda a, b: a + b, [7]))  # 7

# reduce 拼接字符串
print(reduce(lambda a, b: a + b, ["a", "b", "c"]))  # abc


# partial 偏函数
def add(a, b, c=0):
    return a + b + c


add5 = partial(add, 5)
print(add5(10))  # 15 (5 + 10)
print(add5(10, 2))  # 17 (5 + 10 + 2)

add5c1 = partial(add, 5, c=1)
print(add5c1(3))  # 9 (5 + 3 + 1)

# partial 绑定全部参数
add_all = partial(add, 1, 2, 3)
print(add_all())  # 6

# partial 与 lambda
double = partial(lambda x: x * 2)
print(double(21))  # 42

# callable 判定
print(callable(add5))  # True

# 错误路径: 空序列无初始值
try:
    reduce(lambda x, y: x, [])
except TypeError as e:
    print("TE:", e)


# wraps / lru_cache / singledispatch / partial 内省属性
def deco(f):
    @functools.wraps(f)
    def wrapper(*a, **k):
        return f(*a, **k)

    return wrapper


@deco
def foo(a, b=2):
    "doc foo"
    return a + b


print("w-name:", foo.__name__)
print("w-call:", foo(1))
calls = [0]


@functools.lru_cache(maxsize=None)
def fib(n):
    calls[0] += 1
    return n if n < 2 else fib(n - 1) + fib(n - 2)


print("fib:", fib(10))
print("fib-calls:", calls[0])
print("fib-again:", fib(10), calls[0])

# cache_info 为 namedtuple 形态: 字段属性 / 索引 / 元组值相等 / 类型名 CacheInfo
ci = fib.cache_info()
print("ci-type:", type(ci).__name__)
print("ci-repr:", ci)
print("ci-fields:", (ci.hits, ci.misses, ci.maxsize, ci.currsize))
print("ci-idx:", ci[0], ci[3])
print("ci-iter:", tuple(ci))
print("ci-eq:", ci == ci)
print("ci-len:", len(ci))


@functools.singledispatch
def f(x):
    return "default"


@f.register(int)
def _(x):
    return "int"


print("sd-int:", f(1), f("a"))

# registry 活视图 (CPython mappingproxy: 键为类对象, object 项即默认实现)
print("sd-reg-type:", type(f.registry).__name__)
print("sd-reg-len:", len(f.registry))
print("sd-reg-keys:", sorted(k.__name__ for k in f.registry))
print("sd-reg-obj:", f.registry[object] is f.__wrapped__)
print("sd-reg-call:", f.registry[int]("x"))
print("sd-reg-in:", int in f.registry, float in f.registry)
p = functools.partial(foo, 10, b=3)
print("p-func:", p.func.__name__)
print("p-args:", p.args)
print("p-kw:", p.keywords)

# partialmethod: 预绑定实参的方法描述符 (实例调用插 self, 类级调用为裸函数)
class PM:
    def m(self, x, y=2):
        return ("m", x, y)

    pm = functools.partialmethod(m, 1)
    pm2 = functools.partialmethod(m, 1, y=9)
    standalone = functools.partialmethod(lambda a, b: a + b, 10)


pm_inst = PM()
print("pm-call:", pm_inst.pm(3))
try:
    pm_inst.pm2(3)
except TypeError as e:
    print("pm-kw:", e)
print("pm-standalone:", PM.standalone(5))
print("pm-type:", type(PM.pm).__name__)
try:
    PM.pm.func
except AttributeError as e:
    print("pm-attr:", type(e).__name__)
print("pm-repr:", repr(pm_inst.pm)[:18])

# recursive_repr: __repr__ 递归防护 (重入返回 '...', 互嵌对象各自展开)
class Node:
    def __init__(self, name, child=None):
        self.name = name
        self.child = child

    @functools.recursive_repr()
    def __repr__(self):
        return f"{self.name}({self.child!r})"


print("rr-basic:", repr(Node("a")))
loop = Node("p")
loop.child = loop
print("rr-loop:", repr(loop))
print("rr-lambda:", functools.recursive_repr()(lambda x: "rr:" + str(x))(1))


class Tree:
    def __init__(self, children):
        self.children = children

    @functools.recursive_repr()
    def __repr__(self):
        return f"Tree({self.children!r})"


print("rr-list-rec:", repr(Tree(["a", "b"])))

# singledispatchmethod: 按首实参类型分派 (跳过 self, 实现以 (self, arg) 调用)
class SDM:
    @functools.singledispatchmethod
    def method(self, arg):
        return ("default", arg)

    @method.register(int)
    def _(self, arg):
        return ("int", arg)

    @method.register(str)
    def _(self, arg):
        return ("str", arg)


sdm = SDM()
print("sdm-int:", sdm.method(1))
print("sdm-str:", sdm.method("x"))
print("sdm-default:", sdm.method(1.5))
print("sdm-type:", type(SDM.method).__name__)
print("sdm-register:", callable(SDM.method.register))

# lru_cache 有限 maxsize 的真 LRU 淘汰 (命中刷新位次, 逐条淘汰最久未用)
@functools.lru_cache(maxsize=2)
def lf(x):
    return ("lf", x)


lf(1)
lf(2)
lf(1)  # 命中刷新 1 的位次
lf(3)  # 淘汰 2 (最久未用), 保留 1
print("lru-info:", lf.cache_info())
print("lru-hit:", lf(1))
print("lru-info2:", lf.cache_info())
lf(4)  # 淘汰 3
print("lru-info3:", lf.cache_info())
print("lru-miss:", lf(2))  # 2 已被淘汰, 重算


@functools.lru_cache(maxsize=1)
def lf1(x):
    return x


lf1("a")
lf1("b")
lf1("a")
print("lru1:", lf1("a"))
print("lru1-info:", lf1.cache_info())

