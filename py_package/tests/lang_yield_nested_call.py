# 生成器 yield 子表达式与嵌套调用的交互测试
# 对应 v0.5.0-alpha.4 的 P1-16:
# yield 语句中的嵌套用户函数调用不得重置生成器的 yield 位置计数,
# 否则该语句会被反复重放直至触达步数上限 (RuntimeError: maximum step count exceeded)

log = []


def s(tag, v):
    log.append(tag)
    return v


# === 单层: yield 的值表达式是嵌套调用 ===
def g1():
    yield s("a", 1)


print("g1:", list(g1()))
print("log1:", log)
log.clear()


# === 字面量 + 嵌套调用 ===
def g2():
    yield s("b", 1)
    yield 2


print("g2:", list(g2()))
print("log2:", log)
log.clear()


# === 嵌套调用作为 yield 之后的语句 ===
def g3():
    yield 1
    yield s("c", 2)


print("g3:", list(g3()))
print("log3:", log)
log.clear()


# === for 循环 + yield 前缀子表达式 + 嵌套调用 ===
def g4():
    for i in range(3):
        v = s("d", i) * (yield i)
        yield v


x = g4()
print("g4:", next(x))
try:
    print("g4b:", x.send(100))
except StopIteration:
    pass
print("log4:", log)
log.clear()


# === yield from 与 yield 子表达式交替 (原始报告的组合) ===
def g5():
    r = s("e", 1) + (yield 10)
    yield r


def g6():
    for i in range(3):
        v = s("f", i) * (yield i)
        yield v


def g7():
    yield from range(3)
    yield 9


y = g5()
next(y)
try:
    y.send(5)
except StopIteration:
    pass

z = g6()
next(z)
try:
    z.send(100)
except StopIteration:
    pass

print("g7:", list(g7()))
print("log5:", log)


# === 生成器内迭代另一个生成器 ===
def inner():
    for i in range(2):
        yield i


def outer():
    for v in inner():
        yield v * 10
    yield 99


print("outer:", list(outer()))


# === 多个生成器交替推进 ===
def alt():
    for i in range(2):
        yield s("g", i) * 2


a = alt()
b = alt()
print("alt:", next(a), next(b), next(a), next(b))
print("log6:", log)
