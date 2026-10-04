# 职责: 类体作用域细则 (P0-25): 方法闭包跳过类作用域、方法默认参数读类体变量、嵌套类、类体 nonlocal、walrus、推导式
# 比对: same_output

x = "module"


class A:
    x = "class"

    def m(self):
        return x

    def get_default(self, v=x):
        return v


print(A().m())
print(A().get_default())


def f():
    v = 1

    class K:
        w = 2

        def n(self):
            return v

    return K


print(f()().n(), f().w)

# 嵌套类: 内层方法闭包跳过类作用域
y = "outer-module"


class Outer:
    y = "outer-class"

    class Inner:
        def im(self):
            return y


print(Outer.Inner().im())

# nonlocal 在类体内 (CPython 3.12): 目标在更外层函数作用域
def outer_fn():
    v = 1

    def inner_fn():
        class KC:
            nonlocal v
            v = 9

        KC()

    inner_fn()
    return v


print(outer_fn())

# nonlocal 目标在直接外层函数
def outer_fn2():
    v2 = 0

    class KD:
        nonlocal v2
        v2 = 6

    return v2


print(outer_fn2())

# walrus 落类字典
class W:
    (ww := 5)

print(W.ww)

# 类体推导式与生成器
class G:
    squares = [i * i for i in range(4)]
    evens = {i for i in range(6) if i % 2 == 0}

print(G.squares, sorted(G.evens))

# 嵌套类可达
class Outer2:
    base = 100

    class Inner2:
        derived = 5

print(Outer2.Inner2.derived, Outer2.base)
