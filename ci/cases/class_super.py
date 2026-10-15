# 职责: super() 零参与双参调用链
# 比对: same_output

# super() 支持测试


# 基本继承: super() 调用父类方法
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return self.name + " makes a sound"


class Dog(Animal):
    def __init__(self, name):
        super().__init__(name)

    def speak(self):
        return super().speak() + " (from Dog)"


d = Dog("Buddy")
print(d.speak())  # Buddy makes a sound (from Dog)


# 多层继承链
class A:
    def val(self):
        return 1


class B(A):
    def val(self):
        return super().val() + 10


class C(B):
    def val(self):
        return super().val() + 100


print(C().val())  # 111


# super() 与属性访问
class Base:
    def __init__(self):
        self.x = 10

    def get_x(self):
        return self.x


class Sub(Base):
    def get_x(self):
        return super().get_x() * 2


s = Sub()
print(s.get_x())  # 20


# 双参数 super(Class, obj)
class P:
    def greet(self):
        return "parent"


class Q(P):
    def greet(self):
        return "child"


q = Q()
print(super(Q, q).greet())  # parent


# super() 与运算符重载结合
class Num:
    def __init__(self, v):
        self.v = v

    def value(self):
        return self.v


class BetterNum(Num):
    def value(self):
        return super().value() + 1000


n = BetterNum(5)
print(n.value())  # 1005



# super() 属性写入穿透到实例 (CPython 一律 AttributeError)
class SA:
    def __init__(self):
        self.zzz = 0

    def set_through_super(self):
        try:
            super().zzz = 5
            return "no-error"
        except AttributeError as e:
            return "AE"

    def get_zzz(self):
        return self.zzz


s = SA()
print(s.set_through_super())
print(s.get_zzz())  # 实例未被改写


# 未定义属性同样 AttributeError
class SB:
    def setit(self):
        try:
            super().missing = 1
            return "no-error"
        except AttributeError:
            return "AE"


print(SB().setit())


# superclass 定义的可写数据描述符同样不触发 __set__: CPython 的 super 对象无实例字典,
# 属性写入一律 AttributeError (setter 不被调用, 实例不被改写)
class HolderBase:
    def __init__(self):
        self._x = 0

    @property
    def x(self):
        return self._x

    @x.setter
    def x(self, v):
        self._x = v


class Holder(HolderBase):
    def set_via_property(self):
        try:
            super().x = 99
            return "no-error"
        except AttributeError:
            return "AE"


h = Holder()
print(h.set_via_property())
print(h.x)  # 0, setter 未被调用
