# __index__ 协议与 bool 下标 (与 CPython 行为一致)

class Idx:
    def __init__(self, v):
        self.v = v

    def __index__(self):
        return self.v


class Negative:
    def __index__(self):
        return -2


print("abcd"[Idx(2)])
print("abcd"[True], "abcd"[False])
print([10, 20, 30][Idx(1)])
print((4, 5, 6)[Idx(-1)])
print(b"abc"[Idx(0)], b"abc"[True])
r = range(2, 20, 2)
print(r[Idx(3)], r[True], r[False])

# 负数下标回绕
print("abcd"[Idx(-1)], [1, 2, 3][Negative()], (4, 5, 6)[Idx(-3)])

# 切片分量 (start/stop/step) 均经 __index__ 转换
print("abcdef"[Idx(1):Idx(4)])
print([1, 2, 3, 4, 5, 6][Idx(1):Idx(5):Idx(2)])
print("abcdef"[::Idx(2)])
print(b"abcdef"[Idx(2):])
print((1, 2, 3, 4, 5, 6)[True:Idx(5):2])
print(range(10)[Idx(1):Idx(8):Idx(3)])
print("abcdef"[Idx(-5):Idx(-1)])
print([1, 2, 3][Idx(3):], [1, 2, 3][:Idx(-3)])

# 下标赋值 / 切片赋值 / 删除
lst = [1, 2, 3, 4]
lst[Idx(0)] = 9
print(lst)
lst[True] = 7
print(lst)
lst[Idx(1):Idx(3)] = [7, 8]
print(lst)
del lst[Idx(0)]
print(lst)
del lst[False]
print(lst)
lst[Idx(0):Idx(2)] = "xy"
print(lst)

# 元组切片仍返回元组
print((1, 2, 3, 4)[Idx(1):], type((1, 2, 3, 4)[True:2]).__name__)

# __index__ 返回 bool (CPython 3.12 接受, 仅弃用提示)


class BoolIdx:
    def __index__(self):
        return True


print("abcd"[BoolIdx()])

# 字典键不做 __index__ 转换
d = {1: "a"}
try:
    print(d[Idx(1)])
except KeyError:
    print("KeyError")


# __index__ 返回非 int: 各序列的取值与切片均明确报 TypeError


class Bad:
    def __index__(self):
        return "x"


for container in ["abcd", [1, 2], (1, 2), b"ab", range(3)]:
    try:
        container[Bad()]
    except TypeError:
        print("T:ok")
    try:
        container[Bad():2]
    except TypeError:
        print("S:ok")
    try:
        container[0:"x"]
    except TypeError:
        print("W:ok")


# 未定义 __index__: 取值与删除均明确报 TypeError
class Plain:
    pass


for container2 in ["abcd", [1, 2], (1, 2), b"ab", range(3)]:
    try:
        container2[Plain()]
    except TypeError:
        print("N:ok")
    try:
        del [1, 2][Plain()]
    except TypeError:
        print("D:ok")


# __index__ 内 raise: 原异常照常传播
class Raiser:
    def __index__(self):
        raise KeyError("k")


try:
    [1, 2][Raiser()]
except KeyError as e:
    print("R:", e)

# namedtuple 继承元组的下标语义
from collections import namedtuple

P = namedtuple("P", ["x", "y"])
p = P(1, 2)
print(p[Idx(1)], p[True])
try:
    p["a"]
except TypeError:
    print("NT:ok")


# int 子类实例直接作下标
class MyInt(int):
    pass


print("abcd"[MyInt(1)], [1, 2, 3][MyInt(-1)])
print("done")
