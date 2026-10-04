# 职责: 类体方法组装即时性 (P0-25): property/setter/deleter、classmethod/staticmethod、限定名、__set_name__/__init_subclass__ 次序、类与方法装饰器、super 定位
# 比对: same_output

# property + setter + deleter
class P:
    def __init__(self):
        self._v = 0

    @property
    def v(self):
        return self._v

    @v.setter
    def v(self, val):
        self._v = val

    @v.deleter
    def v(self):
        self._v = -1


p = P()
p.v = 7
print(p.v)
del p.v
print(p.v)

# classmethod / staticmethod
class M:
    factor = 3

    @classmethod
    def scaled(cls, v):
        return cls.factor * v

    @staticmethod
    def plain(v):
        return v + 1

    def norm(self, v):
        return v


print(M.scaled(2), M().scaled(2), M.plain(1), M().plain(1), M().norm(5))

# 方法限定名与 repr
print(M.norm.__qualname__, M.norm.__name__)

# 类体内 print 方法对象 (def 时即绑定)
class Q:
    def m(self):
        return 1

    fn = m

print(callable(Q.fn), Q().fn())

# __set_name__ / __init_subclass__ 次序
class Desc:
    def __set_name__(self, owner, name):
        print("set_name", owner.__name__, name)


class Base:
    def __init_subclass__(cls, **kw):
        print("init_subclass", cls.__name__, sorted(kw))


class Child(Base):
    d = Desc()


# 类装饰器
def deco(cls):
    cls.decoed = True
    return cls


@deco
class D:
    v = 1

print(D.v, D.decoed)

# 方法装饰器与内建组合
def shout(fn):
    def wrapper(*a, **k):
        return fn(*a, **k) + "!"
    return wrapper


class E:
    @shout
    def hello(self):
        return "hi"

    @classmethod
    def chello(cls):
        return "yo"

print(E().hello(), E.chello())

# 方法默认参数读类体变量(定义期)
class F:
    unit = 10

    def mul(self, v=unit):
        return v * 2

print(F().mul())

# super() 定位
class GBase:
    def who(self):
        return "base"


class GChild(GBase):
    def who(self):
        return "child+" + super().who()

print(GChild().who())

# 继承方法查找 + 类属性遮蔽
class HBase:
    tag = "base"
    def shared(self):
        return "shared"


class HChild(HBase):
    tag = "child"

print(HChild.tag, HBase.tag, HChild().shared())

# 类体内 raise 语句
class R:
    try:
        raise ValueError("boom")
    except ValueError as e:
        note = str(e)

print(R.note)

# match 语句在类体
class MM:
    v = "b"
    kind = ""
    match v:
        case "a":
            kind = "A"
        case "b":
            kind = "B"

print(MM.kind)
