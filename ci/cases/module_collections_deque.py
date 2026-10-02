# duty: collections.deque 的双向端操作/maxlen/rotate/索引与比较
# 比对: same_output
from collections import deque

d = deque([1, 2, 3])
print(d)
print(deque(), deque("ab"), deque([1, 2], maxlen=3))
dm = deque(maxlen=2)
dm.append(1)
dm.append(2)
dm.append(3)
print(dm)
d.appendleft(0)
d.extendleft([-1])
print(d)
print(d[1], len(d))
d[0] = 99
print(d)
try:
    d[0:2]
except TypeError as e:
    print("TS:", e)
print(d.pop(), d.popleft())
print(d == deque([99, 2]), d == [99, 2])
print(2 in d)
e = deque([1, 1, 2])
print(e.count(1), e.index(2))
e.rotate(1)
print(e)
e.rotate(-2)
print(e)
e.remove(2)
print(e)
e.reverse()
print(e)
print(e.copy(), e.copy() is e)
print(e.maxlen)
try:
    deque().pop()
except IndexError as err:
    print("IE:", err)
try:
    e.remove(42)
except ValueError as err:
    print("VR:", err)
try:
    e.index(42)
except ValueError as err:
    print("VI:", err)
print(type(deque()).__name__)
