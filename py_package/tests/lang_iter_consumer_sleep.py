# Feature: 内建消费器 + 生成器 + time.sleep 挂起循环 (P0-27 回归)
# 生成器步内 sleep 挂起后, 各内建消费形态的重放轮必须越过睡眠点继续消费

import time
import itertools
import operator

def g():
    for i in [5, 6, 7]:
        time.sleep(0)
        yield i

def g2():
    for i in [0, 1, 2]:
        time.sleep(0)
        yield i

print('-'.join(str(x) for x in g()))
print(list(itertools.pairwise(g())))
print([(k, list(v)) for k, v in itertools.groupby(g2(), key=lambda x: x < 2)])
print(operator.countOf(g(), 6))
print(list(enumerate(g2())))
print([*g2()])
print([*g2(), 99])
print((*g2(),))
print({*g2()})
print(sorted({*g2()}))
print(list(map(lambda x: x * 2, g2())))
print(list(filter(lambda x: x > 0, g2())))
print(min(g()))
print(max(g()))
print(sum(g()))
print(any(x > 6 for x in g()))
print(all(x > 0 for x in g()))
print(list(reversed([1, 2, 3])))
