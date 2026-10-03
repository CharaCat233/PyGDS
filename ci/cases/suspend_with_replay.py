# 职责: with 体与 __exit__ 内挂起的重放 (进入标记不重复执行, P0-22 暂存叠加)
# 比对: same_output

import time

log = []


class CM:
    def __init__(self, name):
        self.name = name

    def __enter__(self):
        log.append("enter:" + self.name)
        return self.name

    def __exit__(self, t, v, tb):
        log.append("exit:" + self.name)
        return False


# 场景 1: with 体挂起 (sleep) 后重放, 不得重复执行 __enter__ (进入标记)
with CM("s1"):
    print("before-sleep")
    time.sleep(0.05)
    print("after-sleep")
print(log)

# 场景 2: 多管理器 + 体挂起: 重放后两个管理器都只进入一次
log.clear()
with CM("a"), CM("b"):
    time.sleep(0.05)
    print("body2")
print(log)

# 场景 3: __enter__ 内挂起: 重放续延进入, 完成后不重复调用
class SlowEnter:
    def __enter__(self):
        log.append("slow-enter-begin")
        time.sleep(0.05)
        log.append("slow-enter-end")
        return "slow"

    def __exit__(self, t, v, tb):
        log.append("slow-exit")
        return False


log.clear()
with SlowEnter() as v:
    print("body3", v)
print(log)

# 场景 4: __exit__ 内挂起且异常在途: P0-22 暂存, 恢复后异常继续传播
class SlowExit:
    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        log.append("slow-exit:%s" % (t.__name__ if t else "none"))
        time.sleep(0.05)
        log.append("slow-exit-done")
        return False


log.clear()
try:
    with SlowExit():
        raise ValueError("boom")
except ValueError as e:
    print("caught4", e)
print(log)

# 场景 5: 抑制 + __exit__ 挂起叠加: 恢复后真值返回仍抑制
class SupSleep:
    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        log.append("supsleep:%s" % (t.__name__ if t else "none"))
        time.sleep(0.05)
        return True


log.clear()
with SupSleep():
    print("body5")
    raise KeyError("k")
print("after5")
print(log)

# 场景 6: 陷阱 #9 探针变体 (生成器 + sleep + 内建消费器) 外包 with:
# 体挂起重放经生成器步与消费窗口双通道, 多管理器进入仍各一次
log.clear()


def gen6():
    with CM("g6a"), CM("g6b"):
        for i in range(2):
            time.sleep(0.05)
            yield i


print(list(gen6()))
print(log)
