# 职责: async def 内 yield 合法化为异步生成器 (基础形态: 类型, repr, async for, 裸 return)
# 比对: same_output


# async def 体内 yield: 调用返回 async_generator 对象 (体不执行)
async def agen():
    yield 1
    yield 2


g = agen()
print("type:", type(g).__name__)
print("repr-prefix:", repr(g)[:22])

# async for 驱动: 产出值即元素, 耗尽以 StopAsyncIteration 结束 (return 值不交付)
async def drive():
    out = []
    async for x in g:
        out.append(x)
    try:
        await g.__anext__()
    except StopAsyncIteration:
        out.append("SAI")
    return out


c = drive()
try:
    c.send(None)
except StopIteration as e:
    print("afor:", e.value)

# 裸 return 合法; yield 后被 await 的值不被自动 await
async def inner():
    return 99


async def agen2():
    try:
        yield inner()
    finally:
        print("agen2-fin")


g2 = agen2()


async def drive2():
    v = await g2.__anext__()
    # 产出值不被自动 await: 仍为协程对象, 可手动 await 驱动
    inner_val = await v
    r = await g2.aclose()
    print("aclose:", r, "inner:", inner_val)
    return type(v).__name__


c = drive2()
try:
    c.send(None)
except StopIteration as e:
    print("yielded-not-awaited:", e.value)
