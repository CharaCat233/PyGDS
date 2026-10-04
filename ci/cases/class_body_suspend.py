# 职责: 类体挂起重放 (P0-25): 类体内 sleep 挂起后副作用不重复、流控中挂起、with/生成器/函数内类体与基类求值重放
# 比对: same_output

import time


def slow(v):
    time.sleep(0.05)
    return v


# 类体内 sleep 挂起: 重放后已完成语句副作用不重复
class S1:
    print("enter")
    a = slow(1)
    b = slow(2)
    print("exit")

print(S1.a, S1.b)

# 循环中挂起
class S2:
    acc = 0
    for i in range(3):
        acc += slow(i)
        print("iter", i)

print(S2.acc)

# 类体内 with 管理器挂起
class Trace:
    def __init__(self, name):
        self.name = name

    def __enter__(self):
        print("enter", self.name)
        time.sleep(0.05)
        return self

    def __exit__(self, *exc):
        print("exit", self.name)
        return False


class S3:
    with Trace("t1"):
        held = slow(3)

print(S3.held)

# 类体在函数内、函数调用挂起后恢复
def build():
    class S4:
        got = slow(4)
        print("built")
    return S4


print(build().got)

# 类体挂在 try/except 中
class S5:
    try:
        val = slow(5)
    except Exception:
        val = -1

print(S5.val)

# 类体 + 生成器 + 内建消费器 (陷阱 #9 形态)
def gen():
    for k in range(3):
        time.sleep(0.05)
        yield k


class S6:
    print("before")
    collected = list(gen())
    print("after")

print(S6.collected)

# 类体在生成器函数体内按步执行
def stepper():
    class S7:
        step1 = slow(7)
        print("s7-first")
        step2 = slow(8)
    yield S7.step1
    yield S7.step2


g = stepper()
print(next(g))
print(next(g))

# 基类求值挂起重放(副作用吸收)
def base_factory():
    print("base-called")
    time.sleep(0.05)
    return object


class S8(base_factory()):
    tag = "s8"

print(S8.tag)

# 类体挂起后方法与属性仍完整可用
class S9:
    print("s9-start")
    data = slow(9)

    def get(self):
        return self.data * 2

print(S9().get())
