# 职责: 表达式内 yield/yield from 求值与传播
# 比对: same_output

# (yield 0) + (yield from inner()): inner 耗尽后 yield from 值为 None,
# None + None 触发 TypeError, 两种驱动形态的产出与异常均须一致

def inner():
    yield 1
    yield 2

def gen():
    v = (yield 0) + (yield from inner())
    yield v

# next 逐步驱动: 0, 1, 2 之后抛 TypeError
x = gen()
print(next(x))
print(next(x))
print(next(x))
try:
    print(next(x))
except TypeError as e:
    print("TE:", e)

# list 驱动: 消费到 TypeError 为止, 异常向外传播
try:
    print(list(gen()))
except TypeError as e:
    print("TE2:", e)
