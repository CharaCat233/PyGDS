# 职责: copy 模块的浅拷贝与深拷贝 (memo、环、容器分派与协议)
# 比对: same_output

import copy

l = [1, [2]]
s = copy.copy(l)
print(s is not l, s[0] is l[0], s[1] is l[1])
t = (1, [2])
print(copy.copy(t) is t)
fs = frozenset([1, 2])
print(copy.copy(fs) is fs)
ba = bytearray(b"ab")
cb = copy.copy(ba)
print(cb is not ba, bytes(cb))
d = copy.deepcopy(l)
print(d is not l, d[0] is l[0], d[1] is not l[1])
a = []
a.append(a)
ad = copy.deepcopy(a)
print(ad[0] is ad)
shared = [1]
box = [shared, shared]
bd = copy.deepcopy(box)
print(bd[0] is bd[1], bd[0] is not shared)
print(copy.deepcopy({"x": (1, [2])})["x"][1])
print(copy.deepcopy(5), copy.deepcopy("s"), copy.deepcopy(None))
print(copy.Error is copy.error, copy.Error.__name__)


class C:
    def __init__(self):
        self.v = [1]

    def __copy__(self):
        out = C()
        out.v = self.v
        return out

    def __deepcopy__(self, memo):
        print("deep-memo:", isinstance(memo, dict))
        out = C()
        out.v = copy.deepcopy(self.v, memo)
        return out


c = C()
cc = copy.copy(c)
print(cc is not c, cc.v is c.v)
dd = copy.deepcopy(c)
print(dd is not c, dd.v is not c.v)
print(copy.deepcopy(c) is not c)

import collections
import random

dq = collections.deque([1, [2]], maxlen=3)
dq2 = copy.copy(dq)
print(dq2 is not dq, list(dq2), dq2.maxlen, dq2[1] is dq[1])
dq3 = copy.deepcopy(dq)
print(list(dq3), dq3[1] is not dq[1])

r1 = random.Random(1)
r2 = copy.copy(r1)
print([r1.random() for _ in range(3)] == [r2.random() for _ in range(3)])

try:
    copy.copy(memoryview(b"ab"))
except TypeError as e:
    print("mv", e)
