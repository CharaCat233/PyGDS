# Lang: super() 与 MRO 协作 (两参数形式 / 类方法 / 异常子类 / 匹配)


class A:
    def hello(self):
        return "A-hello"


class B(A):
    def hello(self):
        return "B+" + super(B, self).hello()


class C(B):
    def hello(self):
        return "C+" + super().hello()


print(C().hello())


class A2:
    @classmethod
    def kind(cls):
        return "A2-" + cls.__name__


class B2(A2):
    @classmethod
    def kind(cls):
        return "B2+" + super().kind()


print(B2.kind())
print(B2().kind())


class E1(KeyError, IndexError):
    pass


e = E1("m")
print(str(e), repr(e), e.args)
try:
    raise E1("z")
except IndexError as ie:
    print("as IndexError:", str(ie))
except KeyError:
    print("unreachable")


class M1:
    __match_args__ = ("x",)

    def __init__(self, x):
        self.x = x


class M2:
    __match_args__ = ("y",)

    def __init__(self, y):
        self.y = y


class Obj(M2, M1):
    def __init__(self, y):
        self.y = y


o = Obj(7)
match o:
    case Obj(y):
        print("matched y:", y)
    case _:
        print("no match")


class DA:
    v = 1


class DB:
    w = 2


TD = type("TD", (DA, DB), {"k": 3})
print(TD.v, TD.w, TD.k, [x.__name__ for x in TD.__mro__])
print(isinstance(TD(), DA), isinstance(TD(), DB), issubclass(TD, DB))
