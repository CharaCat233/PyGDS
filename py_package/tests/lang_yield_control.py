# 生成器控制测试 (send / yield from / throw / close)

# send 注入值
def gsend():
    v = yield 1
    print("recv:", v)
    v = yield 2
    print("recv:", v)
g = gsend()
print(next(g))              # 1
print(g.send("hello"))      # recv: hello / 2
try:
    g.send("world")         # recv: world, 生成器结束抛 StopIteration
except StopIteration:
    print("send-done")

# send 到未启动生成器 (非 None 报 TypeError)
g0 = gsend()
try:
    g0.send("x")
except TypeError as e:
    print("TypeError:", e)

# send(None) 启动生成器
g1 = gsend()
print(g1.send(None))        # 1

# 表达式级 yield: x = yield v
def gexpr():
    x = yield 10
    yield x
gx = gexpr()
print(next(gx))             # 10
print(next(gx))             # None (send 值默认为 None)

# yield from 基本
def gyf():
    yield 0
    yield from [1, 2, 3]
    yield from "ab"
    yield 9
print(list(gyf()))          # [0, 1, 2, 3, 'a', 'b', 9]

# yield from 子生成器 (子 return 值)
def sub():
    yield 1
    return "sub-result"
def parent():
    r = yield from sub()
    yield "got:" + r
print(list(parent()))       # [1, 'got:sub-result']

# yield from + islice 消费无限生成器
from itertools import islice
def counter():
    n = 0
    while True:
        yield n
        n += 1
def take5():
    yield from islice(counter(), 5)
print(list(take5()))        # [0, 1, 2, 3, 4]

# throw: 在挂起位置抛出异常, 可被生成器体内 except 捕获
def gth():
    try:
        yield 1
        yield 2
    except ValueError:
        yield 100
it = gth()
print(next(it))             # 1
print(it.throw(ValueError("e")))  # 100
try:
    next(it)
except StopIteration:
    print("throw-done")

# close: 注入 GeneratorExit, finally 执行
def gcl():
    try:
        yield 1
        yield 2
    finally:
        print("finally")
itc = gcl()
print(next(itc))            # 1
itc.close()
try:
    next(itc)
except StopIteration:
    print("closed")

# send 注入 None 时 is None 判定 (send 值必须为单例 None)
def gnone():
    n = 0
    while True:
        received = yield n
        if received is not None:
            n = received
        n += 1
gn = gnone()
print(next(gn))             # 0
print(gn.send(10))          # 11
print(gn.send(None))        # 12 (None 不改变 n)
print(next(gn))             # 13

# send 与 yield from 混合 (send 不转发给子生成器, 只恢复外层)
def gsub2():
    yield 1
    yield 2
def gouter2():
    yield "before"
    yield from gsub2()
    yield "after"
go = gouter2()
print(next(go))             # before
print(next(go))             # 1
print(next(go))             # 2
print(next(go))             # after

print("done")
