# 职责: async def 协程对象生命周期 (创建不执行, send/throw/close, 耗尽重用与首发非 None)
# 比对: same_output


async def add(a, b):
    return a + b


# 调用返回协程对象, 体不执行: repr 带地址 (经运行器归一化对齐), send 驱动至完成
async def outer():
    x = await add(1, 2)
    y = await add(x, 10)
    return y


c = outer()
print("repr-prefix:", repr(c)[:17])
try:
    c.send(None)
except StopIteration as e:
    print("result:", e.value)

# 耗尽后重用: RuntimeError (与生成器的 StopIteration 不同, CPython 协程语义)
try:
    c.send(None)
except RuntimeError as e:
    print("finished:", e)

# 未启动首发非 None: TypeError
async def simple():
    return 5


c2 = simple()
try:
    c2.send(42)
except TypeError as e:
    print("send-nonnone:", e)
try:
    c2.send(None)
except StopIteration as e:
    print("simple:", e.value)

# 未启动 throw: 异常直接外抛, 体不执行
async def never():
    return "unreached"


c3 = never()
try:
    c3.throw(ValueError("early"))
except ValueError as e:
    print("throw-early:", e)

# close 未启动: 体不执行且不发 never-awaited; 已启动后 close 走 finally 且 GeneratorExit 静默
async def fin():
    try:
        await add(1, 1)
    finally:
        print("fin-ran")


c4 = fin()
print("close-early:", c4.close())
c5 = fin()
try:
    c5.send(None)
except StopIteration:
    pass
print("close-after:", c5.close())
try:
    c5.send(None)
except RuntimeError as e:
    print("after-close:", e)

# throw 进挂起中的协程: 体内可捕获, 捕获并 return 后 throw 以 StopIteration(返回值) 收尾
class Aw:
    def __await__(self):
        yield 1
        return "aw"


async def catcher():
    try:
        v = await Aw()
        return "no"
    except ValueError as e:
        return "caught:" + str(e)


c6 = catcher()
c6.send(None)
try:
    c6.throw(ValueError("v"))
except StopIteration as e:
    print("throw-suspended:", e.value)

# 协程方法形式: 限定名进入 repr 与 warning (此处只验驱动)
class M:
    async def m(self):
        return 9


c7 = M().m()
try:
    c7.send(None)
except StopIteration as e:
    print("method:", e.value)
