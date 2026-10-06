# 职责: __iter__ 返回 self 的用户迭代器挂起重放
# 比对: same_output
# ref: I2-60

# __iter__ 返回 self、__next__ 体内 sleep 的消费形态: 挂起必须经迭代器的
# suspended 标记向消费器传播 (此前被当作耗尽或 null 元素), 重放轮从产出
# 日志续读已交付元素、仅对新元素继续驱动 __next__。用户实例状态跨重放轮
# 推进与睡眠去重计数配合, 逐步收敛, 输出与 CPython 的逐元素消费一致

import time

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

class SelfIterFields:
    def __init__(self, tag):
        self.tag = tag
        self.n = 0
    def __iter__(self):
        return self
    def __next__(self):
        time.sleep(0)
        self.n += 1
        if self.n > 2:
            raise StopIteration
        return "%s-%d" % (self.tag, self.n)

# 内建消费器
print(list(SelfIter()))
print([x for x in SelfIter()])
print(sum(SelfIter()))
# 带字段实例 (语句重放走构造链实例重建路径)
print(list(SelfIterFields("a")))
print(list(SelfIterFields("b")))
# for 循环消费
total = 0
for x in SelfIter():
    total += x
print(total)
# next() 内建逐步消费
it = iter(SelfIter())
print(next(it))
print(next(it))
print(next(it))
# 对照: __iter__ 返回 iter(生成器) 形态 (挂起在生成器步内)
def g():
    yield 10
    time.sleep(0)
    yield 20

class WrapGen:
    def __iter__(self):
        return iter(g())

print(list(WrapGen()))
print(list(zip(WrapGen(), WrapGen())))
