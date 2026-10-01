# 职责: 类创建钩子触发次序、链式调用与失败回滚
# 比对: same_output

# __init_subclass__ 与 __set_name__ 类创建钩子 (alpha.4)
log = []


class Base:
    def __init_subclass__(cls):
        log.append("sub:" + cls.__name__)

    def __set_name__(self, owner, name):
        log.append("name:" + name + "@" + owner.__name__)


class Child(Base):
    attr = Base()


print(log)

# 次序: __set_name__ 先于 __init_subclass__
order = []


class Tracker:
    def __init_subclass__(cls):
        order.append("init_sub")

    def __set_name__(self, owner, name):
        order.append("set_name")


class Ordered(Tracker):
    t = Tracker()


print(order)

# 新类自定义的钩子对自己的创建不生效, 对子类生效
chain = []


class P:
    def __init_subclass__(cls):
        chain.append("P" + cls.__name__)


class Q(P):
    def __init_subclass__(cls):
        chain.append("Q" + cls.__name__)


class R(Q):
    pass


print(chain)

# classmethod 形式与显式 super() 链式调用
cm_log = []


class M:
    @classmethod
    def __init_subclass__(cls):
        cm_log.append("cm" + cls.__name__)


class N(M):
    pass


print(cm_log)

chain2 = []


class S1:
    def __init_subclass__(cls):
        chain2.append("S1" + cls.__name__)
        super().__init_subclass__()


class S2(S1):
    def __init_subclass__(cls):
        chain2.append("S2" + cls.__name__)
        super().__init_subclass__()


class S3(S2):
    pass


print(chain2)

# 非描述符属性 (函数 / 数值 / None) 不触发 __set_name__
sn_log = []


class SN:
    def __set_name__(self, o, n):
        sn_log.append(n)


class W:
    a = SN()
    b = SN()
    c = 5
    d = None
    e = lambda self: 1


print(sn_log)

# 继承链上的描述符只在定义类创建时触发
inherited = []


class Desc(SN):
    pass


class Holder:
    f = Desc()


class Holder2(Holder):
    pass


print(sn_log)

# type() 三参形式同样触发
type_log = []


class TBase:
    def __init_subclass__(cls):
        type_log.append(cls.__name__)


def make():
    return type("TDyn", (TBase,), {})


make()
print(type_log)

# 钩子抛异常: 类创建失败, 名字不绑定
try:
    class XFail:
        def __init_subclass__(cls):
            raise ValueError("hook fail")

    class YFail(XFail):
        pass
except ValueError as e:
    print("VE:", e)
try:
    print(YFail)
except NameError:
    print("not bound")

sn_fail = []


class SNFail:
    def __set_name__(self, owner, name):
        raise RuntimeError("sn fail")


try:
    class ZFail:
        a = SNFail()
except RuntimeError as e:
    print("RE:", e)
try:
    print(ZFail)
except NameError:
    print("not bound 2")
