# 职责: 调用侧多次 */** 混排与求值序
# 比对: same_output

# PEP 448 调用侧泛化: *a 之后的定位实参按书写次序拼装, 多次 * / ** 混用


def f(*args, **kw):
    return (list(args), sorted(kw.items()))


d = {"a": 1, "b": 2}

# 星参之后的定位实参不再前插
print(f(1, *[2, 3], 4))
print(f(*[1], 2, *[3]))
print(f(*[1, 2], "x"))
print(f(0, *[1], 2, *[3], 4))

# 多组 ** 与普通关键字混排
print(f(**d, k=9, **{"c": 3}))
print(f(x=1, **d, y=2))


def g(a, b, c):
    return (a, b, c)


# 星参展开与位置/关键字参数的正确对应
print(g(*[1], 2, *[3]))
print(g(1, *[2], **{"c": 3}))
print(g(*[1], **{}, b=2, c=3))

# 关键字参数求值次序与合并次序


def side(x):
    print("side", x)
    return x


def h(**kw):
    return sorted(kw.items())


print(h(m=side(1), **{"n": side(2)}))
print(h(**{"a": side(3)}, **{"b": side(4)}))

# 重复关键字报 TypeError (CPython: got multiple values for keyword argument)
try:
    h(**{"a": 1}, a=2)
except TypeError as e:
    print("TE:", "multiple values" in str(e))
try:
    h(a=2, **{"a": 1})
except TypeError as e:
    print("TE2:", "multiple values" in str(e))
try:
    h(**{"a": 1}, **{"a": 2})
except TypeError as e:
    print("TE3:", "multiple values" in str(e))
