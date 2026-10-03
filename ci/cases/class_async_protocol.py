# 职责: 用户类异步迭代与异步上下文协议 (__aiter__/__anext__/__aenter__/__aexit__) 与 aiter/anext 内建
# 比对: same_output


# async for: __anext__ 协程逐个 await 驱动, StopAsyncIteration 结束循环
class AIter:
    def __init__(self, n):
        self.n = n
        self.i = 0

    def __aiter__(self):
        return self

    async def __anext__(self):
        if self.i >= self.n:
            raise StopAsyncIteration
        self.i += 1
        return self.i


async def afor():
    out = []
    async for x in AIter(3):
        out.append(x)
    return out


c = afor()
try:
    c.send(None)
except StopIteration as e:
    print("afor:", e.value)

# async for + break 与元组目标解包
class APairIter:
    def __init__(self):
        self.i = 0

    def __aiter__(self):
        return self

    async def __anext__(self):
        self.i += 1
        if self.i > 4:
            raise StopAsyncIteration
        return (self.i, self.i * 10)


async def afor2():
    out = []
    async for k, v in APairIter():
        if k == 3:
            break
        out.append((k, v))
    return out


c = afor2()
try:
    c.send(None)
except StopIteration as e:
    print("afor2:", e.value)

# async for 协议缺失文案
async def afor_bad():
    async for x in 5:
        pass


c = afor_bad()
try:
    c.send(None)
except TypeError as e:
    print("no-aiter:", e)


class OnlyAiter:
    def __aiter__(self):
        return self


async def afor_bad2():
    async for x in OnlyAiter():
        pass


c = afor_bad2()
try:
    c.send(None)
except TypeError as e:
    print("no-anext:", e)

# async with: 进入按序退出逆序, as 绑定, 异常经 __aexit__ (返回值决定抑制)
log = []


class ACtx:
    def __init__(self, name):
        self.name = name

    async def __aenter__(self):
        log.append("aenter:" + self.name)
        return self.name

    async def __aexit__(self, t, v, tb):
        log.append("aexit:" + self.name + (":exc" if t else ":none"))
        return False


async def awith():
    async with ACtx("a") as x, ACtx("b"):
        log.append("body:" + x)


c = awith()
try:
    c.send(None)
except StopIteration:
    pass
print("awith:", log)

log.clear()


async def awith2():
    async with ACtx("c"):
        raise ValueError("boom")


c = awith2()
try:
    c.send(None)
except ValueError as e:
    print("awith-exc:", e)
print("awith2:", log)


class ASup:
    async def __aenter__(self):
        return self

    async def __aexit__(self, t, v, tb):
        return True


async def awith3():
    async with ASup():
        raise KeyError("k")
    return "after"


c = awith3()
try:
    c.send(None)
except StopIteration as e:
    print("asup:", e.value)

# async with 协议缺失文案 (退出侧带 missed 后缀)
class NoAenter:
    pass


async def awith4():
    async with NoAenter():
        pass


c = awith4()
try:
    c.send(None)
except TypeError as e:
    print("no-aenter:", e)


class OnlyAenter:
    async def __aenter__(self):
        return self


async def awith5():
    async with OnlyAenter():
        pass


c = awith5()
try:
    c.send(None)
except TypeError as e:
    print("no-aexit:", e)


class SyncHook:
    def __aenter__(self):
        return 1

    async def __aexit__(self, t, v, tb):
        return False


async def awith6():
    async with SyncHook():
        pass


c = awith6()
try:
    c.send(None)
except TypeError as e:
    print("sync-aenter:", e)

# aiter() / anext() 内建: anext 返回 __anext__ 的协程, 默认值形态吞 StopAsyncIteration
async def anext_chain():
    it = aiter(AIter(2))
    v1 = await anext(it)
    v2 = await anext(it)
    try:
        await anext(it)
    except StopAsyncIteration:
        print("anext-exhausted")
    v3 = await anext(it, "dflt")
    return [v1, v2, v3]


c = anext_chain()
try:
    c.send(None)
except StopIteration as e:
    print("anext-chain:", e.value)


async def anext_bad():
    await anext(5)


c = anext_bad()
try:
    c.send(None)
except TypeError as e:
    print("anext-bad:", e)


async def aiter_bad():
    aiter(5)


c = aiter_bad()
try:
    c.send(None)
except TypeError as e:
    print("aiter-bad:", e)
