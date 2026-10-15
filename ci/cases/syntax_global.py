# 职责: global 与 nonlocal 多名声明各作用域
# 比对: same_output

# global 多名声明
a = 0
b = 0
c = 0


def set_two():
    global a, b
    a = 1
    b = 2


set_two()
print(a, b, c)


def set_three():
    global a, b, c
    a = 10
    b = 20
    c = 30


set_three()
print(a, b, c)

# 声明后读取走模块全局
counter = 5


def read_global():
    global counter
    return counter


print(read_global())

# 类体内多名 global
g1 = 0
g2 = 0


class Config:
    global g1, g2
    g1 = 7
    g2 = 8


print(g1, g2)
print(getattr(Config, "g1", "MISS"))

# 函数内多名 global 的读改写
total = 0
hits = 0


def bump():
    global total, hits
    total += 1
    hits += 1


bump()
bump()
print(total, hits)


# nonlocal 多名 (对照)
def outer():
    x = 1
    y = 2

    def inner():
        nonlocal x, y
        x = 10
        y = 20

    inner()
    return x, y


print(outer())


# 跨两级闭包链的 nonlocal: 目标变量在祖父级作用域
def counter():
    total = 0

    def mid():
        def add():
            nonlocal total
            total += 1

        add()
        add()

    mid()
    return total


print(counter())


# 嵌套函数内 global (此前静默预创建模块全局, 且读取回退闭包链命中外层局部)
# CPython: 声明不绑定名字; 声明名读取/删除直达模块全局; 未赋值即读取报 NameError
def outer():
    counter_local = 0

    def f():
        global counter_local
        counter_local += 1

    f()
    return counter_local


try:
    print(outer())
except NameError as e:
    print("NE:", e)
try:
    print(counter_local)
except NameError as e:
    print("NE2:", e)
gv = 5


def read_g():
    global gv
    return gv


print(read_g())


def bump():
    global gv
    gv += 1
    return gv


print(bump(), gv)
