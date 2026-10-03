# 职责: 异步生成器驱动协议 (asend / athrow / aclose, 手动 __anext__, 关闭后耗尽)
# 比对: same_output


# asend 注入值, athrow 在挂起点注入异常 (体内可捕获并续 yield)
async def agen():
    try:
        v = yield 1
        v = yield v + 1
    except ValueError as e:
        yield "caught:" + str(e)
    finally:
        print("agen-fin")


g = agen()


async def drive():
    v1 = await g.asend(None)
    v2 = await g.asend(10)
    v3 = await g.athrow(ValueError("v"))
    try:
        await g.asend(None)
    except StopAsyncIteration:
        print("exhausted: SAI")
    return [v1, v2, v3]


c = drive()
try:
    c.send(None)
except StopIteration as e:
    print("asend-athrow:", e.value)

# aclose: 注入 GeneratorExit 走 finally, 返回 None, 之后耗尽
async def agen2():
    try:
        yield 1
    finally:
        print("agen2-fin")


g2 = agen2()


async def drive2():
    v = await g2.__anext__()
    print("got:", v)
    r = await g2.aclose()
    print("aclose:", r)
    try:
        await g2.__anext__()
    except StopAsyncIteration:
        print("after-close: SAI")


c = drive2()
try:
    c.send(None)
except StopIteration:
    pass

# __anext__ 可等待对象的形态 (asend 族), 与 aiter() 内建
async def agen3():
    yield 10
    yield 20


g3 = agen3()


async def drive3():
    step = g3.__anext__()
    print("step-type:", type(step).__name__)
    it = aiter(g3)
    a = await anext(it)
    b = await anext(it)
    return [a, b]


c = drive3()
try:
    c.send(None)
except StopIteration as e:
    print("manual:", e.value)
