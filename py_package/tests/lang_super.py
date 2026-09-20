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
print(d.speak())           # Buddy makes a sound (from Dog)

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

print(C().val())           # 111

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
print(s.get_x())           # 20

# 双参数 super(Class, obj)
class P:
    def greet(self):
        return "parent"

class Q(P):
    def greet(self):
        return "child"

q = Q()
print(super(Q, q).greet()) # parent

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
print(n.value())           # 1005

print("done")
