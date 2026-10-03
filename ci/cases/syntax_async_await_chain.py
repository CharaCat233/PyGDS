# 职责: await 求值语义 (协程嵌套同步驱动, 用户 __await__ 委托, 不可等待与非法迭代器文案)
# 比对: same_output


async def add(a, b):
    return a + b


# await 链: 内层协程同步驱动至完成, 返回值逐层上取
async def chain3():
    return "deep"


async def chain2():
    return await chain3()


async def chain1():
    return await chain2()


c = chain1()
try:
    c.send(None)
except StopIteration as e:
    print("chain:", e.value)

# await 用户 __await__: 产出值外抛 (经 send 逐个取出), return 值为 await 结果
class Awaitable:
    def __await__(self):
        yield "a1"
        yield "a2"
        return "aw-done"


async def drive():
    return await Awaitable()


c = drive()
print("a1:", c.send(None))
print("a2:", c.send(None))
try:
    c.send(None)
except StopIteration as e:
    print("aw-done:", e.value)

# await 不可等待对象: object X can't be used in 'await' expression (类型名小写形态)
async def bad_int():
    return await 42


c = bad_int()
try:
    c.send(None)
except TypeError as e:
    print("await-int:", e)


def sync_fn():
    return None


async def bad_none():
    await sync_fn()


c = bad_none()
try:
    c.send(None)
except TypeError as e:
    print("await-none:", e)


async def bad_gen():
    def gen():
        yield 1
    await gen()


c = bad_gen()
try:
    c.send(None)
except TypeError as e:
    print("await-gen:", e)

# __await__ 返回非迭代器: TypeError
class BadAwait:
    def __await__(self):
        return 5


async def drive_bad():
    await BadAwait()


c = drive_bad()
try:
    c.send(None)
except TypeError as e:
    print("badawait:", e)

# 协程体内异常经 await 链传播并可捕获
async def raiser():
    raise KeyError("k")


async def catcher():
    try:
        await raiser()
    except KeyError as e:
        return "caught:" + str(e)


c = catcher()
try:
    c.send(None)
except StopIteration as e:
    print("nested-exc:", e.value)

# async def 内嵌套 async def: 内层调用返回协程, await 驱动
async def outermost():
    async def inner():
        return 7
    return await inner()


c = outermost()
try:
    c.send(None)
except StopIteration as e:
    print("nested-def:", e.value)
