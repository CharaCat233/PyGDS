# duty: 函数式 staticmethod/classmethod/property 与 operator.index
# 比对: same_output
import operator


def _get(self):
    return self._v


def _set(self, v):
    self._v = v


def _make(cls, x):
    return cls.tag + str(x)


class C:
    tag = "T-"
    name = property(_get, _set)
    make = classmethod(_make)
    greet = staticmethod(lambda: "hi")


c = C()
c.name = 7
print(c.name)
print(C.make(3))
print(C.greet())
prop = C.__dict__["name"]
print(prop.fget.__name__, prop.fset.__name__)
try:
    operator.index(3.5)
except TypeError as e:
    print("IE:", e)
try:
    operator.index("a")
except TypeError as e:
    print("IE2:", e)
print(operator.index(True), operator.index(5))


class Idx:
    def __index__(self):
        return 4


print(operator.index(Idx()))
