# 职责: 类与对象的内省属性及异常 traceback
# 比对: same_output

# 内省属性: __class__ / 类 __dict__ / 异常 __traceback__ (P2-21)
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
