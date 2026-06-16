# Edge: __str__ vs __repr__

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
print(repr(os))              # <OnlyStr object at ...>, 由于 PyGDS 无模块, 故可能与此处行为不一致, 预期出现 <OnlyStr object>

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