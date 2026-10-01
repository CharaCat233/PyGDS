# 职责: 递归容器 repr、property 删除器与槽位限制
# 比对: same_output

# 容器与类: 递归容器 repr / property deleter / slots 多形态
lst = [1, 2]
lst.append(lst)
print(lst)
d = {}
d["self"] = d
print(d)
inner = [1]
outer = [inner, inner]
inner.append(outer)
print(outer)

class P:
    def __init__(self):
        self._x = 0
    @property
    def x(self):
        return self._x
    @x.setter
    def x(self, v):
        self._x = v * 2
    @x.deleter
    def x(self):
        self._x = -1
p = P()
p.x = 5
print(p.x)
del p.x
print(p.x)

class Slotted:
    __slots__ = ["a", "b"]
s = Slotted()
s.a = 1
s.b = 2
print(s.a, s.b)
try:
    s.c = 3
except AttributeError as e:
    print("SL")
