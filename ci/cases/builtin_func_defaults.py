# 职责: 函数 __defaults__ / __kwdefaults__ 的读取、写入与调用期默认值解析
# 比对: same_output


def f(a, b=2, *, c=3, d=4):
    return (a, b, c, d)


print(f.__defaults__, f.__kwdefaults__)
print(f(1))
try:
    f.__defaults__ = 5
except TypeError as e:
    print("TE", e)
try:
    f.__kwdefaults__ = [1]
except TypeError as e:
    print("TE2", e)
f.__defaults__ = (7, 8, 9)
print(f.__defaults__, f(1))
print(f(1, 2, d=9))
f.__kwdefaults__ = {"c": 30, "zz": 1}
print(f.__kwdefaults__, f(1, c=3, d=5))
print(f.__kwdefaults__["zz"])
f.__kwdefaults__ = None
print(f.__kwdefaults__)
try:
    print(f(1, d=4))
except TypeError as e:
    print("TE3", e)
f.__defaults__ = None
print(f.__defaults__)
try:
    print(f(1))
except TypeError as e:
    print("TE4", e)


def g(*, a=1, b=2):
    return a + b


g.__kwdefaults__ = {"a": 10}
try:
    print(g(), g.__kwdefaults__)
except TypeError as e:
    print("TE5", e)
print(g(b=2), g.__kwdefaults__)
g.__defaults__ = (5,)
try:
    print(g.__defaults__, g())
except TypeError as e:
    print("TE6", e)
print(g.__defaults__, g(a=1, b=2))
