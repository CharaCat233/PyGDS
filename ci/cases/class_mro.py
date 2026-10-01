# 职责: 多继承 C3 线性化、__mro__ 与属性查找
# 比对: same_output


class A:
    def who(self):
        return "A"

    def only_a(self):
        return "oa"

    common = "ca"


class B:
    def who(self):
        return "B"

    def only_b(self):
        return "ob"

    common = "cb"


class C(A, B):
    pass


c = C()
print(c.who(), c.only_a(), c.only_b(), c.common)
print([k.__name__ for k in C.__mro__])
print([k.__name__ for k in C.mro()])
print(type(C.mro()).__name__)
print(isinstance(c, A), isinstance(c, B), isinstance(c, C))
print(issubclass(C, A), issubclass(C, B), issubclass(B, A), issubclass(C, C))
print("only_a" in dir(C) and "only_b" in dir(C) and "who" in dir(C))


class D(B, A):
    pass


print(D().who(), D.common)


class Plain:
    pass


try:
    class Conflict(A, B, A):
        pass
except TypeError as e:
    print("conflict bases rejected")


class LeftM:
    def m(self):
        return "L"


class RightM:
    def m(self):
        return "R"


class SubM(LeftM, RightM):
    pass


print(SubM().m())
print([k.__name__ for k in SubM.__mro__])
