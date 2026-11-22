# 职责: staticmethod / classmethod / member_descriptor 包装对象的类型身份与 repr
# 比对: same_output


class F:
    a = staticmethod(lambda: 1)
    b = classmethod(lambda cls: 2)
    __slots__ = ()


for name in ("a", "b"):
    obj = F.__dict__[name]
    print(name, type(obj).__name__, repr(obj))

print(F().a(), F.b())
print(type(staticmethod(lambda: 0)).__name__)
print(type(classmethod(len)).__name__)


class G:
    __slots__ = ("v",)


print(type(G.__dict__["v"]).__name__, repr(G.__dict__["v"]))
print(repr(staticmethod(len)), repr(classmethod(len)))
