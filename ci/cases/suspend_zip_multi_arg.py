# 职责: zip 多参消费包装迭代器类的挂起重放
# 比对: same_output
# ref: I2-61

# zip 对每个参数各自取迭代器后逐参消费: 某参数消费中途挂起时必须立即传播
# 挂起并放弃本次调用 (语句重放后逐参续读), 不得在 _suspended 置位下继续取
# 下一个参数的迭代器——用户 __iter__ 调用会假挂起返回 null, 被误报为
# zip() arg is not iterable。重放轮各参数经生成器记忆按出现次序复用,
# 输出与 CPython 的逐参并行消费一致

import time

def g():
    yield 1
    time.sleep(0)
    yield 2
    time.sleep(0)
    yield 3

class W:
    def __iter__(self):
        return iter(g())

class WF:
    def __init__(self, v):
        self.v = v
    def __iter__(self):
        return iter(g())

class SelfIter:
    def __init__(self):
        self.n = 0
    def __iter__(self):
        return self
    def __next__(self):
        time.sleep(0)
        self.n += 1
        if self.n > 3:
            raise StopIteration
        return self.n

# 单参对照: 消费挂起后重放续读
print(list(W()))
print(sum(W()))
# 双参消费同一包装迭代器类 (修复形态)
print(list(zip(W(), W())))
# 双参: 实例带字段, 语句重放走实例重建路径
print(list(zip(WF(1), WF(2))))
# 三参同类
print(list(zip(W(), W(), W())))
# 内建序列与包装迭代器类混合
print(list(zip([7, 8], W())))
# __iter__ 返回 self 的用户迭代器双参消费 (同族交叉形态)
print(list(zip(SelfIter(), SelfIter())))
