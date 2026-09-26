# match 类模式: isinstance, __match_args__, 关键字, 值模式, 运行时错误

class Point:
    __match_args__ = ("x", "y")
    def __init__(self, x, y):
        self.x = x
        self.y = y

class Color:
    RED = 1
    BLUE = 2

# 位置子模式
match Point(0, 5):
    case Point(0, y):
        print("origin y", y)
    case Point(x, y):
        print("pt", x, y)

# 关键字子模式
match Point(3, 4):
    case Point(x=3, y=4):
        print("kw pt")

# 位置与关键字混合
match Point(3, 4):
    case Point(3, y=4):
        print("mixed")

# 无参类模式只做 isinstance
class Shape:
    pass

class Circle(Shape):
    __match_args__ = ("r",)
    def __init__(self, r):
        self.r = r

class Square(Shape):
    def __init__(self, s):
        self.s = s

def f_cls(x):
    match x:
        case Circle(r=0):
            return "dot"
        case Circle(r):
            return ("circle", r)
        case Square():
            return "square"
        case Shape():
            return "shape"
        case _:
            return "n"
print(f_cls(Circle(0)), f_cls(Circle(5)), f_cls(Square(2)), f_cls(Shape()))

# 继承 __match_args__
class Point3(Point):
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z
match Point3(1, 2, 3):
    case Point3(a, b):
        print("inherit", a, b)

# 类模式 + or
match Circle(2):
    case Circle(r=1) | Circle(r=2):
        print("cls-or")

# 类模式 + as
match Point(1, 2):
    case Point(0, _) as p:
        print("no")
    case Point(x, y) as whole:
        print("cls-as", x, y, type(whole) is Point)

# 值模式 (点号常量)
match 2:
    case Color.RED:
        print("red")
    case Color.BLUE:
        print("blue")

# 值模式 + or
match Color.RED:
    case Color.RED | Color.BLUE:
        print("color-or")

# 值模式做映射键
match {Color.BLUE: "b"}:
    case {Color.BLUE: v}:
        print("valkey", v)

# 内建类型类模式
match 5:
    case int():
        print("int yes")
match "s":
    case int():
        print("bad")
    case str():
        print("str yes")

# 内建类型位置子模式报错
try:
    match 5:
        case int(v):
            pass
except TypeError as e:
    print("T-int:", e)

# 内建类型单位置子模式直接绑定主题 (match_self 语义, 含 bool 是 int 子类)
def f_int(x):
    match x:
        case int(v):
            return ("int", v is x)
    return "no"
print(f_int(True), f_int(5), f_int("s"), f_int(2.5))

def f_cont(x):
    match x:
        case list(l):
            return "list"
        case tuple(t):
            return "tuple"
        case dict(d):
            return "dict"
        case set(s):
            return "set"
        case bytes(b):
            return "bytes"
    return "no"
print(f_cont([1]), f_cont((1,)), f_cont({1: 2}), f_cont({1}), f_cont(b'AB'))

# 用户类与内建同名时不具备单位置绑定
class list:
    pass
def f_same(x):
    match x:
        case list(v):
            return "m"
    return "no"
try:
    f_same(list())
except TypeError as e:
    print("same-name:", e)

# 位置子模式与关键字重复属性 (运行时 TypeError)
class Dup:
    __match_args__ = ("x", "y")
    def __init__(self, x, y):
        self.x = x
        self.y = y
try:
    match Dup(1, 2):
        case Dup(x, x=1):
            pass
except TypeError as e:
    print("T-dup:", e)

# __match_args__ 数量不足报错
class P1:
    __match_args__ = ("x",)
    def __init__(self, x):
        self.x = x

try:
    match P1(1):
        case P1(a, b):
            pass
except TypeError as e:
    print("T-args:", e)

# 无 __match_args__ 报错
class P0:
    def __init__(self, x):
        self.x = x

try:
    match P0(1):
        case P0(v):
            pass
except TypeError as e:
    print("T-noargs:", e)

# 关键字属性缺失视为不匹配 (CPython 语义: 不抛异常, 落到后续分支)
match P1(1):
    case P1(y=2):
        print("no")
    case _:
        print("attr-miss-no-match")

# 属性 getter 抛非 AttributeError 异常仍然传播
class G:
    __match_args__ = ("v",)
    def __init__(self):
        self._v = 1
    @property
    def v(self):
        raise ValueError("boom")

try:
    match G():
        case G(v=1):
            print("no")
except ValueError as e:
    print("prop-raise:", e)

# __match_args__ 不是元组
class L1:
    __match_args__ = ["a"]
    def __init__(self, a):
        self.a = a

try:
    match L1(1):
        case L1(v):
            pass
except TypeError as e:
    print("T-type:", e)

# 位置子模式递归
class Line:
    __match_args__ = ("a", "b")
    def __init__(self, a, b):
        self.a = a
        self.b = b
match Line(Point(1, 2), Point(3, 4)):
    case Line(Point(1, y1), Point(x2, 4)):
        print("nested-cls", y1, x2)

# isinstance 语义: 用户类实例不参与序列匹配
class Seq:
    def __init__(self):
        self.data = [1, 2]
match Seq():
    case [a, b]:
        print("no")
    case _:
        print("user-cls-no-seq")

print("done_class")
