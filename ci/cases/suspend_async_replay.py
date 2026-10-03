# 职责: 协程体内挂起的重放 (await 链 / async for / async with 内 sleep, 多协程交替驱动)
# 比对: same_output

import time

log = []


async def slow_add(a, b):
    time.sleep(0.05)
    return a + b


async def outer():
    x = await slow_add(1, 2)
    y = await slow_add(x, 10)
    return y


c = outer()
try:
    c.send(None)
except StopIteration as e:
    print("nested-sleep:", e.value)

# async for 迭代器 __anext__ 内挂起 (陷阱 #9 探针变体: 协程 + sleep + 驱动重放)
class SlowAIter:
    def __init__(self, n):
        self.n = n
        self.i = 0

    def __aiter__(self):
        return self

    async def __anext__(self):
        if self.i >= self.n:
            raise StopAsyncIteration
        self.i += 1
        time.sleep(0.05)
        return self.i


async def afor():
    out = []
    async for x in SlowAIter(3):
        out.append(x)
    return out


c = afor()
try:
    c.send(None)
except StopIteration as e:
    print("afor-sleep:", e.value)

# __aenter__ / __aexit__ 内挂起: 进入标记防重复进入, 退出按状态续延
class SlowCtx:
    def __init__(self, name):
        self.name = name

    async def __aenter__(self):
        log.append("aenter:" + self.name)
        time.sleep(0.05)
        return self.name

    async def __aexit__(self, t, v, tb):
        log.append("aexit:" + self.name)
        time.sleep(0.05)
        return False


async def awith():
    async with SlowCtx("a") as x:
        log.append("body:" + x)


c = awith()
try:
    c.send(None)
except StopIteration:
    pass
print("awith-sleep:", log)

# 多协程交替驱动: 各自的 sleep 挂起经语句重放独立推进, 互不串扰
log.clear()


async def stepper(tag):
    for i in range(2):
        time.sleep(0.05)
        log.append(tag + str(i))


a = stepper("a")
b = stepper("b")
try:
    a.send(None)
except StopIteration:
    pass
try:
    b.send(None)
except StopIteration:
    pass
print("steppers:", log)
