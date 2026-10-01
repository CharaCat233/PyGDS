# 职责: __str__/__repr__ 定义与内置回退
# 比对: same_output


class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __str__(self):
        return "Point({}, {})".format(self.x, self.y)

    def __repr__(self):
        return "Point(x={}, y={})".format(self.x, self.y)

p = Point(3, 5)
print(str(p))                # Point(3, 5)
print(repr(p))               # Point(x=3, y=5)

# 只有 __str__
class OnlyStr:
    def __str__(self):
        return "str only"

os = OnlyStr()
print(str(os))               # str only
print(repr(os))              # 默认对象 repr (双端经归一化比对: CPython 带模块限定与地址, PyGDS 为简化形式)

# 只有 __repr__ (fallback)
class OnlyRepr:
    def __repr__(self):
        return "repr only"

or_ = OnlyRepr()
print(str(or_))              # repr only
print(repr(or_))             # repr only

# 内置类型
print(str(42))               # 42
print(repr(42))              # 42
print(str("hi"))             # hi
print(repr("hi"))            # 'hi'
print(str([1, 2, 3]))        # [1, 2, 3]
print(repr([1, 2, 3]))       # [1, 2, 3]

print("done")
