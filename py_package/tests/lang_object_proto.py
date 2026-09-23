# 用户类协议测试: __eq__ / __hash__ / 迭代协议 / 多重赋值目标
# 对应 v0.5.0-alpha.3 的 P1-1 ~ P1-4

# === __eq__ 参与容器操作 (in / remove / index / count) ===
class A:
    def __init__(self, x):
        self.x = x

    def __eq__(self, other):
        return isinstance(other, A) and self.x == other.x


a1 = A(1)
a2 = A(1)
a3 = A(2)
print("eq:", a1 == a2, a1 == a3)
print("ne:", a1 != a2)
print("in:", a2 in [a1], a3 in [a1])
lst = [a1, a3]
lst.remove(a2)
print("remove:", len(lst))
print("index:", [a1, a3].index(a2))
print("count:", [a1, a2].count(a1))

# === __hash__ 用于字典键 / 集合元素 ===
class P:
    def __init__(self, x):
        self.x = x

    def __hash__(self):
        return hash(self.x)

    def __eq__(self, o):
        return isinstance(o, P) and self.x == o.x


d = {P(1): "a", P(2): "b"}
print("lookup:", d[P(1)], d[P(2)])
print("dlen:", len(d))
d[P(3)] = "c"
print("dlen2:", len(d))
try:
    d[P(9)]
except KeyError:
    print("KeyError")
print("dedup:", len({P(1), P(1), P(2)}))
print("setin:", P(1) in {P(1)}, P(3) in {P(1)})
print("hash:", hash(P(7)))


# 未定义 __hash__ 的类不可作键 (与 CPython 一致)
class NoHash:
    def __init__(self):
        self.x = 1


try:
    {NoHash(): 1}
except TypeError as e:
    print("unhashable:", e)

# 元组可作键
t = {(1, 2): "tuple"}
print("tuple key:", t[(1, 2)])


# === 用户类迭代协议 __iter__ / __next__ ===
class It:
    def __init__(self):
        self.n = 0

    def __iter__(self):
        return self

    def __next__(self):
        self.n += 1
        if self.n > 3:
            raise StopIteration
        return self.n


print("list:", list(It()))
for v in It():
    print("v:", v)
print("sum:", sum(It()))
print("tuple:", tuple(It()))
print("sorted:", sorted(It()))
print("max:", max(It()))
print("enumerate:", list(enumerate(It())))
print("in-iter:", 2 in It(), 9 in It())

i = It()
print("next:", next(i), next(i), next(i))
try:
    next(i)
except StopIteration:
    print("stopped")


# __iter__ 为生成器函数
class Gen:
    def __iter__(self):
        yield 1
        yield 2


print("gen-iter:", list(Gen()))
for g in Gen():
    print("g:", g)


# === 多重赋值目标 ===
a = [1, 2, 3]
a[0], a[2] = a[2], a[0]
print("swap:", a)

x, y = 1, 2
x, y = y, x
print("var swap:", x, y)


class C:
    def __init__(self):
        self.p = 0
        self.q = 0


o = C()
o.p, o.q = 7, 8
print("attr:", o.p, o.q)

dd = {}
dd["m"], dd["n"] = 10, 20
print("item:", dd)


class Bag:
    def __init__(self):
        self.data = {}

    def put(self, k, v):
        self.data[k] = v


bag = Bag()
bag.put("z", 5)
print("chained:", bag.data)

p, q = 1, 2
p, q = q, p
print("final:", p, q)

print("done")
