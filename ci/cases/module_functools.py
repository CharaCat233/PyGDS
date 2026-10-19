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

