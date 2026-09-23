# 嵌套生成器内的 sleep 测试 (与 CPython 行为一致)

import time
import operator

# 生成器体内迭代另一个含 sleep 的生成器
def inner():
    for i in range(2):
        time.sleep(0)
        yield i


def outer():
    for x in inner():
        yield x * 10


print(list(outer()))

# 三层嵌套: c() -> b() -> a(), a 内 sleep
def la():
    for i in range(2):
        time.sleep(0)
        yield i


def lb():
    for x in la():
        yield x + 1


def lc():
    for y in lb():
        yield y * 10


print(list(lc()))

# yield from 嵌套
def yf_outer():
    yield from la()


print(list(yf_outer()))

# 生成器内 genexpr + sleep
def ge_outer():
    for v in (x * 2 for x in la()):
        yield v


print(list(ge_outer()))

# 嵌套 + 消费函数
def cb():
    for x in la():
        yield x + 1


print(sum(cb()))
print(sorted(cb()))

# 嵌套 + 嵌套消费
def nb():
    for x in la():
        yield x * 10


print([[y for y in nb()] for _ in range(2)])

# 嵌套 + send: yield from 后继续产出
def sd_outer():
    v = yield from la()
    yield 'got'


print(list(sd_outer()))

# 嵌套 + 闭包: 生成器工厂
def make(n):
    def gen():
        for i in range(n):
            time.sleep(0)
            yield i * 2
    return gen()


def consume(g):
    for x in g:
        yield x


print(list(consume(make(2))))

# 消费点: next() / operator.indexOf() / 字面量 * 解包
def ng():
    time.sleep(0)
    yield 1
    time.sleep(0)
    yield 2


it = ng()
print(next(it))
print(next(it))


def ig():
    for i in [5, 6, 7]:
        time.sleep(0)
        yield i


print(operator.indexOf(ig(), 6))


def sg():
    for i in range(3):
        time.sleep(0)
        yield i


print([*sg()])
print([*sg(), 99])
print((*sg(),))

# 生成器内 sleep 后抛异常 (异常穿过嵌套生成器传播)
def eg():
    time.sleep(0)
    yield 1
    time.sleep(0)
    raise ValueError("mid")


def ec():
    for x in eg():
        yield x


eit = ec()
try:
    print(next(eit))
    next(eit)
except ValueError as e:
    print("caught:", e)

# 异常在 for 循环的最后一条语句处抛出, 也须外传给外层 try
def fg():
    time.sleep(0)
    yield 1
    raise ValueError("late")


try:
    for v in fg():
        print("v:", v)
except ValueError as e:
    print("caught:", e)

# 同上, 但不含 sleep (验证挂起与异常两条传播路径相互独立)
def ng2():
    yield 1
    raise ValueError("boom")


try:
    for v in ng2():
        print("v:", v)
except ValueError as e:
    print("caught:", e)

print("done")
