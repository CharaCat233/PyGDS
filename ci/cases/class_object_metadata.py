# 职责: 堆类的元数据属性面与 dir 条目 (__doc__/__weakref__/__dict__/__module__)
# 比对: same_output


class C:
    """cls doc"""


c = C()
print(c.__doc__, C.__doc__)
print(repr(c.__weakref__), hasattr(c, "__dict__"))
print(repr(C.__weakref__))
print(type(C.__weakref__).__name__)
meta = ["__dict__", "__doc__", "__module__", "__weakref__"]
print([m for m in meta if m in dir(c)])
print([m for m in meta if m in dir(C)])
print("format" in dir("x"), "format" in dir(b"x"))
print("__dict__" in dir(5), "__weakref__" in dir(5))


class S:
    __slots__ = ("v",)


s = S()
print(hasattr(s, "__weakref__"), hasattr(s, "__dict__"))
print("__weakref__" in dir(s), "__dict__" in dir(s))
try:
    print(S.__weakref__)
except AttributeError as e:
    print("AE", e)
