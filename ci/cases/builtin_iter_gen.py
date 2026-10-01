# 职责: iter 对生成器返回自身与耗尽不可重复
# 比对: same_output


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
