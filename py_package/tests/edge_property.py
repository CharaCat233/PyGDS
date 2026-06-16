# Edge: @property 装饰器

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
print(c.radius)              # 5
print(c.area)                # ~78.53975

c.radius = 10
print(c.radius)              # 10
print(c.area)                # ~314.159

# @property 只读
class ReadOnly:
    def __init__(self, v):
        self._v = v

    @property
    def v(self):
        return self._v

ro = ReadOnly(42)
print(ro.v)                  # 42
try:
    ro.v = 100
except AttributeError:
    print("AttributeError")  # AttributeError

print("done")