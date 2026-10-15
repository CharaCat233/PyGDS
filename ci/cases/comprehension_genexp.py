# 职责: 生成器表达式惰性与 next/sum/zip 等消费
# 比对: same_output

# 生成器表达式测试 (惰性生成器)

from itertools import islice, count

# 类型
g = (x * x for x in range(5))
print(type(g))  # <class 'generator'>

# 惰性: 未消费时不求值
print(list(x * x for x in range(5)))  # [0, 1, 4, 9, 16]
print(list(x for x in range(6) if x % 2 == 0))  # [0, 2, 4]

# tuple / 列表推导消费
print(tuple(x for x in range(3)))  # (0, 1, 2)
print([x for x in (x for x in "abc")])  # ['a', 'b', 'c']

# next() 逐次推进 (一次性迭代器)
g1 = (x for x in range(3))
print(next(g1))  # 0
print(next(g1))  # 1
print(list(g1))  # [2] (继续, 已消费 0, 1)
print(list(g1))  # [] (已耗尽)

# next() 默认值
g2 = (x for x in range(1))
print(next(g2, -1))  # 0
print(next(g2, -1))  # -1 (耗尽返回默认值)

# sum / sorted / min / max / any / all
print(sum(x * x for x in range(4)))  # 14
print(sorted(x for x in [3, 1, 2]))  # [1, 2, 3]
print(min(x for x in [5, 3, 9]))  # 3
print(max(x for x in [5, 3, 9]))  # 9
print(any(x > 2 for x in [1, 2, 3]))  # True
print(all(x > 0 for x in [1, 2, 3]))  # True

# enumerate / zip
print(list(enumerate((x for x in ["a", "b"]), start=1)))  # [(1, 'a'), (2, 'b')]
print(list(zip((x for x in [1, 2]), [10, 20])))  # [(1, 10), (2, 20)]

# islice 惰性消费无限生成器
print(list(islice((x for x in count(0, 2)), 4)))  # [0, 2, 4, 6]
print(list(islice((x * x for x in count()), 5)))  # [0, 1, 4, 9, 16]


# 生成器表达式最外层可迭代在创建时急切求值 (此前延迟到首次迭代)
# 创建后重绑同名变量不影响已有生成器
x = [1, 2]
g = (i for i in x)
x = [9, 9]
print(list(g))

# 可迭代自身的 NameError 在创建时机报告 (此前推迟到首次迭代)
try:
    g2 = (i for i in undefined_qq)
    print("no-error")
except NameError as e:
    print("NE:", str(e))


# 嵌套推导式首子句急切, 后续子句仍可在推导式作用域引用前序变量
def gen_nested():
    x = [1, 2]
    g3 = (j for i in [x] for j in i)
    x = [9, 9]
    return list(g3)


print(gen_nested())

# 惰性主体不受影响: 元素表达式在迭代时求值
side = []


def track(v):
    side.append(v)
    return v


g4 = (track(i) for i in [1, 2])
print(side)  # 创建时未求值元素表达式
print(list(g4))
print(side)

# genexpr 对象补 close/send/throw/__next__ (与 def 生成器协议面一致, 此前 AttributeError)
g87 = (x for x in [1, 2])
print(g87.close())
print(g87.close())
try:
    next(g87)
except StopIteration:
    print("SI")
g87b = (x for x in [1, 2])
try:
    print(g87b.send(5))
except TypeError as e:
    print("TE:", e)
g87c = (x for x in [1, 2])
print(g87c.send(None))
print(g87c.send(7))
try:
    print(g87c.send(None))
except StopIteration:
    print("SI2")
g87d = (x for x in [1, 2])
try:
    g87d.throw(ValueError("boom"))
except ValueError as e:
    print("VE:", e)
g87e = (x for x in [1, 2])
print(g87e.__next__())
g87f = (x for x in [1, 2])
print(
    hasattr(g87f, "send"),
    hasattr(g87f, "throw"),
    hasattr(g87f, "close"),
    hasattr(g87f, "__next__"),
)
g87g = (x for x in [1, 2])
try:
    g87g.throw(StopIteration)
except StopIteration:
    print("SI-throw")

# 推导式 for 目标嵌套解包
pairs = [(1, 2), (3, 4)]
print([k for (k, v) in pairs])
print([v for k, v in pairs])
d43 = {"a": 1, "b": 2}
print({k: v for (k, v) in d43.items()})
data43 = [[1, 2], [3, 4]]
print([a + b for [a, b] in data43])
xs43 = [(1, 2, 3), (4, 5, 6)]
print([z for *pre, z in xs43])
print([p for (p, q, r) in xs43])
print([(x, y) for x, y in [(1, 2)]])
print([y for x, (y, z) in [(1, (2, 3))]])

# genexpr repr 含限定名链 (模块级 <genexpr> / 函数内 func.<locals>.<genexpr> / 类体 A.<genexpr>; def 生成器嵌套含 outer.<locals>.inner)
g23 = (x for x in [1])
print(repr(g23))


def gen23():
    return (x for x in [1, 2])


print(repr(gen23()))


def outer23():
    def inner23():
        yield 1

    return inner23()


print(repr(outer23()))


class A23:
    g = (x for x in [1])


print(repr(A23.g))
f23 = lambda: (x for x in [1])
print(repr(f23()))


class A23b:
    def m(self):
        return (x for x in [1])


print(repr(A23b().m()))
