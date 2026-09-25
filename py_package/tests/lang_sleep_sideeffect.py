# 消费含 sleep 的生成器时的副作用与取值测试 (与 CPython 一致)
# 表达式级消费生成器时, 生成器体不得重复执行

import time
from itertools import islice

# 生成器体内的副作用只执行一次
log = []


def a():
    for i in range(2):
        log.append(i)
        time.sleep(0)
        yield i


print(list(a()))
print("log1:", log)

# 各类表达式级消费形态
log2 = []


def b():
    for i in range(2):
        log2.append(i)
        time.sleep(0)
        yield i


print("sum:", sum(b()))
print("log2:", log2)

log3 = []


def c():
    for i in range(2):
        log3.append(i)
        time.sleep(0)
        yield i


print("sorted:", sorted(c()))
print("log3:", log3)

log4 = []


def d():
    for i in range(2):
        log4.append(i)
        time.sleep(0)
        yield i


print("max:", max(d()))
print("log4:", log4)

log5 = []


def e():
    for i in range(2):
        log5.append(i)
        time.sleep(0)
        yield i


print("tuple:", tuple(e()))
print("log5:", log5)

# 推导式与生成器表达式消费
log6 = []


def f():
    for i in range(2):
        log6.append(i)
        time.sleep(0)
        yield i


print([x for x in f()])
print("log6:", log6)

log7 = []


def g():
    for i in range(2):
        log7.append(i)
        time.sleep(0)
        yield i


print(list(x * 10 for x in g()))
print("log7:", log7)

# 产出值依赖被修改的状态时, 元素值本身也须正确
n = 0


def h():
    global n
    for i in range(3):
        n += 1
        time.sleep(0)
        yield n


print(list(h()))
print("n:", n)

# for 语句消费 (迭代器经 resume_info 复用)
log8 = []


def k():
    for i in range(2):
        log8.append(i)
        time.sleep(0)
        yield i


for v in k():
    print("v:", v)
print("log8:", log8)

# 嵌套生成器 + 副作用
log9 = []


def inner():
    for i in range(2):
        log9.append(i)
        time.sleep(0)
        yield i


def outer():
    for x in inner():
        yield x + 1


print("nested:", list(outer()))
print("log9:", log9)

# 嵌套推导式: 外层重启后内层生成器须重新求值
log10 = []


def m():
    for i in range(2):
        log10.append(i)
        time.sleep(0)
        yield i


def wrap():
    for x in m():
        yield x * 10


print([[y for y in wrap()] for _ in range(2)])
print("log10:", log10)

# 闭包工厂
def make(cnt):
    def gen():
        for i in range(cnt):
            time.sleep(0)
            yield i * 2
    return gen()


def consume(it):
    for x in it:
        yield x


print("closure:", list(consume(make(2))))

# islice 惰性消费
log11 = []


def inf():
    idx = 0
    while True:
        log11.append(idx)
        time.sleep(0)
        yield idx
        idx += 1


print("islice:", list(islice(inf(), 3)))
print("log11:", log11)

# 多轮消费同一语句 (语句结束后记忆须清理, 不能跨语句复用)
log12 = []


def p():
    for i in range(2):
        log12.append(i)
        time.sleep(0)
        yield i


print("first:", list(p()))
print("second:", list(p()))
print("log12:", log12)

print("done")
