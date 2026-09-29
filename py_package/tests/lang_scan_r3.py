# 第三轮扫描修复: Counter / chain.from_iterable / 嵌套类 / product repeat / %s 与 __str__ / find 空串
from collections import Counter
from itertools import chain, tee, product
c = Counter("abracadabra")
print(c.most_common(2), c["a"], c["zz"])
print(Counter([1, 2, 2]).total())
print(list(Counter("ab").elements()))
d = Counter("aa") + Counter("aa")
print(d)
print(list(Counter({"x": 3}).elements()), dict(Counter({"x": 3})) == {"x": 3})
print(list(chain.from_iterable([[1], [2, 3]])))
class Outer:
    class Inner:
        def hello(self):
            return "inner"
    def make(self):
        return Outer.Inner()
print(Outer().make().hello(), Outer.Inner().hello())
print(list(product("ab", repeat=2)))
class S:
    def __str__(self):
        return "S-str"
    def __repr__(self):
        return "S-repr"
s = S()
print("%s|%r" % (s, s), "{}".format(s), f"{s} {s!r}")
print("abc".find(""), "abc".find("", 3))
a, b = tee([1, 2, 3])
print(list(a), list(b), type(a).__name__)
