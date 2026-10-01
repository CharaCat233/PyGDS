# Feature: 需要序列的消费器收到生成器时的 TypeError (P0-27 回归)
# random.choices 要求序列, 对生成器取 len 报 TypeError, 文案与 CPython 一致

import random

random.seed(3)

def g():
    for i in range(6):
        yield i

try:
    print(random.choices(g(), k=2))
except TypeError as e:
    print("TE:", e)
