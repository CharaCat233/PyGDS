# 职责: 类与对象的内省属性及异常 traceback
# 比对: same_output


# 内省属性: __class__ / 类 __dict__ / 异常 __traceback__
class C:
    x = 1


inst = C()
print(inst.__class__.__name__)
print(inst.__class__ is C)
print(C.__dict__["x"])
print(type(C.__dict__).__name__)
try:
    C.__dict__["x"] = 2
    print("writable")
except TypeError as e:
    print("readonly")
try:
    raise ValueError("boom")
except ValueError as e:
    print(hasattr(e, "__traceback__"))
print((5).__class__.__name__)
print("s".__class__.__name__)
print(None.__class__.__name__)
print([].__class__.__name__)
print({}.__class__.__name__)
print(().__class__.__name__)
print(len.__class__.__name__)
print((5).__class__ is int)
print("s".__class__ is str)


class E(Exception):
    pass


try:
    raise E("x")
except E as e:
    print(e.__class__.__name__)
print(getattr(inst, "__class__").__name__)
print(hasattr(C, "__dict__"))


# 类对象 __name__/__doc__/__qualname__ 赋值可写 (此前静默丢失)
class D:
    pass


D.__name__ = "Renamed"
print(D.__name__)
D.__qualname__ = "RenamedQ"
print(D.__qualname__)
D.__doc__ = "custom doc"
print(D.__doc__)


class DocStr:
    """builtin doc"""


DocStr.__doc__ = "overwritten"
print(DocStr.__doc__)


# 子类不继承父类的覆写 (沿 MRO 的 class_attrs 不串入)
class P:
    pass


P.__name__ = "PNew"


class Q(P):
    pass


print(Q.__name__)


# __getattribute__ 钩子 (此前不生效, 属性访问落默认查找)
# CPython: 显式属性读取经 __getattribute__ 槽; 隐式协议分派不经钩子
class Hook:
    def __getattribute__(self, name):
        return "hooked:" + name


h = Hook()
print(h.anything)
print(h.foo)
print(getattr(h, "x"))
print(hasattr(h, "y"))


# 隐式协议 (len) 不经 __getattribute__
class LenHook:
    def __getattribute__(self, name):
        return 99

    def __len__(self):
        return 3


print(len(LenHook()))


# property.__doc__ / super 内省属性
class P53:
    x = property(lambda self: 1)


print(P53.x.__doc__)


class A53:
    def m(self):
        s = super()
        print(s.__thisclass__.__name__)
        print(s.__self_class__.__name__)
        print(s.__self__ is self)


class B53(A53):
    pass


B53().m()
