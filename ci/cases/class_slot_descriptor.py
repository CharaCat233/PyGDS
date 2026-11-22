# 职责: __slots__ 校验与槽成员描述符 (冲突报错、类级描述符、取值写值)
# 比对: same_output


class C:
    __slots__ = ("x", "y")

    def __init__(self):
        self.x = 1


c = C()
print(c.x, hasattr(C, "x"), C.x, repr(C.x), type(C.x).__name__)
print("x" in C.__dict__, "y" in C.__dict__)
try:
    print(c.y)
except AttributeError as e:
    print("AE", e)
c.y = 2
print(c.y, hasattr(c, "y"))
del c.y
print(hasattr(c, "y"))
try:
    del c.y
except AttributeError as e:
    print("AE2", e)
try:
    c.z = 3
except AttributeError as e:
    print("AE3", e)

try:
    class F:
        __slots__ = ("v",)
        v = 5
except ValueError as e:
    print("VE", e)

try:
    class G:
        __slots__ = ("m",)

        def m(self):
            return 1
except ValueError as e:
    print("VE2", e)


class H:
    __slots__ = ("x", "x")


print(type(H.__dict__["x"]).__name__)

try:
    class I:
        __slots__ = 5
except TypeError as e:
    print("TE", e)

try:
    class J:
        __slots__ = ("a", 5)
except TypeError as e:
    print("TE2", e)
