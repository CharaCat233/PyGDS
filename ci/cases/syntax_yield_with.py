# 职责: 生成器与 with 交互 (体含 yield, as 绑定跨步, close 与 throw 穿越退出路径)
# 比对: same_output

log = []


class CM:
    def __init__(self, name):
        self.name = name

    def __enter__(self):
        log.append("enter:" + self.name)
        return self.name

    def __exit__(self, t, v, tb):
        log.append("exit:%s:%s" % (self.name, "exc" if t else "none"))
        return False


# 体含 yield: 挂起点在 with 体内, as 绑定跨步保持, 耗尽时正常退出
def gen1():
    with CM("g1") as v:
        yield 1
        yield v
    yield 2


g1 = gen1()
print(next(g1))
print(next(g1))
print(next(g1))
print(log)

# with 语句本身在生成器中可出现多次 (循环内), 每轮独立进入退出
log.clear()


def gen2():
    for i in range(2):
        with CM("g2-%d" % i):
            yield i


print(list(gen2()))
print(log)

# close() 穿越 with: GeneratorExit 在途, __exit__ 收到异常参数后假值放行, close 静默
log.clear()


def gen3():
    with CM("g3"):
        try:
            yield 1
        except GeneratorExit:
            log.append("ge-caught")
            raise


g3 = gen3()
print(next(g3))
g3.close()
print(log)

# __exit__ 抑制 GeneratorExit 后生成器直接收尾: close 正常返回 (不报 ignored)
log.clear()


def gen4():
    with CM("g4"):
        try:
            yield 1
        except GeneratorExit:
            log.append("swallowed")
            return


g4 = gen4()
print(next(g4))
print(g4.close())
print(log)

# throw() 注入异常穿越 with 体: 被内层 except 捕获续 yield, 退出时无异常
log.clear()


def gen5():
    with CM("g5"):
        try:
            yield 1
        except ValueError:
            log.append("throw-caught")
            yield 99
        yield 100


g5 = gen5()
print(next(g5))
print(g5.throw(ValueError("v")))
print(next(g5))
print(log)
