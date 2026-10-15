# 职责: @property 读写与只读拦截
# 比对: same_output


class Circle:
    def __init__(self, radius):
        self._radius = radius

    @property
    def radius(self):
        return self._radius

    @radius.setter
    def radius(self, value):
        if value < 0:
            raise ValueError("radius must be non-negative")
        self._radius = value

    @property
    def area(self):
        return 3.14159 * self._radius * self._radius


c = Circle(5)
print(c.radius)  # 5
print(c.area)  # ~78.53975

c.radius = 10
print(c.radius)  # 10
print(c.area)  # ~314.159


# @property 只读
class ReadOnly:
    def __init__(self, v):
        self._v = v

    @property
    def v(self):
        return self._v


ro = ReadOnly(42)
print(ro.v)  # 42
try:
    ro.v = 100
except AttributeError:
    print("AttributeError")  # AttributeError



# 只读 property 的 fset/fdel 为 None 单例 (此前返回新实例, `is None` 身份比较失败)
class P90:
    @property
    def x(self):
        return 1

    @x.setter
    def x(self, v):
        pass

    @property
    def y(self):
        return 2


p90 = P90()
print(P90.x.fset is None)
print(P90.x.fget is None)
print(P90.y.fset is None)
print(P90.y.fdel is None)
print(P90.x.fset is not None)
print(P90.x.fset.__name__)
print(P90.y.fset)
p90.x = 5
print(p90.x)
print(P90.y.fset is None)
print(P90.y.fdel is None)


# delattr 缺失属性文案 / property 无 deleter 文案
class HostP:
    def __init__(self):
        self.name = "h"


hp = HostP()
try:
    delattr(hp, "zz")
except AttributeError as e:
    print("delattr-missing:", str(e))


class ROProp:
    @property
    def x(self):
        return 42


rp = ROProp()
try:
    del rp.x
except AttributeError as e:
    print("prop-del:", str(e))


# 只读 property 赋值报 CPython 文案 (property 'x' of 'P' object has no setter)
class ROOnly:
    def __init__(self):
        self._v = 3

    @property
    def v(self):
        return self._v


ro = ROOnly()
try:
    ro.v = 9
except AttributeError as e:
    print("ro-set:", type(e).__name__, str(e))
print(ro.v)
