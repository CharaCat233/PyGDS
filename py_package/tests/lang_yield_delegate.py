# yield from 委托与 yield 恢复期子表达式记忆测试
# 对应 v0.5.0-alpha.3 的 P1-13 与 P1-14

# === send 转发到 yield from 子生成器 (PEP 380) ===
def inner():
    v = yield 1
    print("inner got:", v)
    yield 2


def outer():
    yield from inner()


g = outer()
print(next(g))
g.send("X")


# === throw 转发: 子生成器内的 try/except 能捕获 ===
def inner2():
    try:
        yield 1
    except ValueError as e:
        print("inner caught:", e)
        yield 2


def outer2():
    yield from inner2()


g2 = outer2()
print(next(g2))
print(g2.throw(ValueError("boom")))


# === 子生成器的 return 值经 yield from 传出 ===
def acc():
    total = 0
    while True:
        v = yield total
        if v is None:
            break
        total += v
    return total


def delegating():
    r = yield from acc()
    yield r


g3 = delegating()
print(next(g3))
g3.send(5)
g3.send(7)
print(g3.send(None))


# === 委托后继续产出 ===
def sub():
    yield 1
    yield 2


def main():
    yield from sub()
    yield 3


print(list(main()))

# === yield from 非生成器可迭代对象 ===
def from_range():
    yield from range(3)


print(list(from_range()))


def from_list():
    x = yield from [10, 20]
    yield x


print(list(from_list()))


# === yield 恢复期: 挂起点之前的子表达式不重复求值 ===
log = []


def side(tag, v):
    log.append(tag)
    return v


def g4():
    r = side("a", 1) + (yield 10)
    print("g4:", r)


x = g4()
print(next(x))
try:
    x.send(5)
except StopIteration:
    pass


def g5():
    for i in range(3):
        v = side("b", i) * (yield i)
        print("g5:", v)


y = g5()
print(next(y))
try:
    y.send(100)
except StopIteration:
    pass

print("log:", log)

# 参数位置的 yield, 其前面的实参不重复求值
log2 = []


def f(x, y):
    return x + y


def a():
    log2.append("a")
    return 10


def g6():
    print(f(a(), (yield 1)))


gi = g6()
print(next(gi))
try:
    gi.send(2)
except StopIteration:
    pass
print("log2:", log2)

print("done")
