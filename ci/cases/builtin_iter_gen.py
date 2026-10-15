# 职责: iter 对生成器返回自身与耗尽不可重复
# 比对: same_output


def g():
    yield 1
    yield 2


it = iter(g())
print(list(it))
print(list(it))


def h():
    yield "a"


it2 = iter(h())
print(next(it2))
try:
    next(it2)
except StopIteration:
    print("stop")
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


# iter() 对用户迭代器零消费 (此前快照式全量排空副作用提前)
class SideIt:
    def __init__(self):
        self.n = 0

    def __iter__(self):
        return self

    def __next__(self):
        self.n += 1
        if self.n > 3:
            raise StopIteration
        return self.n


s = SideIt()
it = iter(s)
print(it is s)  # 一等迭代器返回自身
print(s.n)  # 零消费 (此前会被排空到 3)
print(next(it))
print(s.n)
print(list(it))
print(s.n)
print(list(it))  # 已耗尽

# 再次 iter() 返回同一对象
print(iter(s) is s)


# 已耗尽生成器 throw (此前被错误转成 StopIteration)
# CPython: 耗尽后 throw 注入的异常原样传播
def tg():
    yield 1


it = tg()
print(next(it))
try:
    next(it)
except StopIteration:
    print("exhausted")
try:
    it.throw(ValueError)
except ValueError:
    print("ValueError-propagated")
except StopIteration:
    print("StopIteration-wrong")


# 未耗尽生成器 throw 在挂起处注入
def tg2():
    try:
        yield 1
    except ValueError:
        print("caught-in-gen")
        yield 2


g2 = tg2()
print(next(g2))
print(g2.throw(ValueError))
