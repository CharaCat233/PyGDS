# class C(*bases) 星参基类 (PEP 448 类侧泛化, P1-60)


class A:
    x = 1


class B:
    x = 2

    def greet(self):
        return "B"


bs = [object]
class C(*bs,):
    pass


print(isinstance(C(), object))

bs2 = [A]
class D(*bs2, B):
    def greet(self):
        return "D+" + super().greet()


print(D().greet(), D.x)

bs3 = [B, A]
class E(*bs3,):
    pass


print(E.x, E().greet())

# 星参基类展开后做直接基类重复检查
try:
    class F(*[A, A]):
        pass
except TypeError as e:
    print("TE:", e)

# 非类基类报 TypeError (文案与 CPython 的元类路径不同, 双端均为 TypeError)
try:
    class G(*[1]):
        pass
except TypeError:
    print("TE2")

# 布尔 / 负数等单继承星参形态
base_list = [A]


class H(*base_list,):
    y = 3


print(H.x, H.y)
