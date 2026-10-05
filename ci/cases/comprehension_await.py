# 职责: 推导式内 await (A 方案): async 函数体内 list / dict / set 推导式的元素 / 键值 / 条件 / 嵌套 / 首子句可迭代中的 await, 同步上下文的专属文案, sleep 挂起重放
# 比对: same_output
# 锚定: CPython 3.12
import time


async def slow(v):
    time.sleep(0)
    return v * 2


async def main():
    r1 = [await slow(x) for x in range(3)]
    print("list", r1)
    r2 = {await slow(x): await slow(1) for x in range(2)}
    print("dict", r2)
    r3 = {await slow(x) for x in range(2)}
    print("set", r3)
    r4 = [await slow(x) for x in range(3) if x > 0]
    print("cond", r4)
    r5 = [[await slow(y) for y in range(2)] for x in range(2)]
    print("nested", r5)
    r6 = [x for it in [(1, 2)] for x in it]
    print("plain", r6)


try:
    main().send(None)
except StopIteration:
    pass
print("done")


# 同步上下文的编译期 SyntaxError 经 exec 动态编译触发 (编译期错误不可捕获)
try:
    exec("def sync_comp(): return [await slow(x) for x in range(1)]")
except SyntaxError as e:
    print("sync:", str(e))


async def give():
    return [7, 8]


async def first_clause(coro):
    return [x for x in await coro]


async def main2():
    print("first", await first_clause(give()))


try:
    main2().send(None)
except StopIteration:
    pass
