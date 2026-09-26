# Feature: iter() 对生成器返回其自身 (耗尽后不可重复消费)

def g():
    yield 1
    yield 2

it = iter(g())
print(list(it))
print(list(it))

def h():
    yield 'a'

it2 = iter(h())
print(next(it2))
try:
    next(it2)
except StopIteration:
    print('stop')
print(iter(it2) is it2)

def k():
    yield 10
    yield 20

it3 = iter(k())
print(next(it3))
print(list(it3))
print(list(it3))
for v in iter(k()):
    print(v)
