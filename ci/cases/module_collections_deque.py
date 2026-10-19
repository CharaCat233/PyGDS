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

# deque 跨型等值/序列比较与边界
# 元素相等统一经 _dsl_eq (此前只认同型元素, 其余落引用恒等)
print(1.0 in deque([1]))
print(deque([True]) == deque([1]))
print(deque([10**20]) == deque([10**21]))
print(deque([10**20]) != deque([10**21]))
print(deque([1, 2]) == deque([1, 2]))
print(deque([1]) == [1])
print(deque([1.0]) == deque([1]))

# 大数下标超界 (此前返回首元素)
try:
    print(deque([1, 2, 3])[10**30])
except IndexError as e:
    print("IE:", str(e))

# rotate 大数 (此前静默不轮转)
d = deque([1, 2, 3])
try:
    d.rotate(10**30)
    print(list(d))
except OverflowError as e:
    print("OE:", str(e))

# 序列字典序比较吞错修复 (deque 与 list 共享 _seq_lex_compare)
try:
    print(deque([1]) < deque(["a"]))
except TypeError as e:
    print("TE:", str(e))

# bool 下标按 int
print(deque([10, 20])[True])
d2 = deque([1, 2, 3])
d2[True] = 99
print(list(d2))

# reversed(deque)
print(list(reversed(deque([1, 2, 3]))))
print(list(reversed(deque([]))))

# deque 方法接受 bool 实参 (bool 是 int 子类)
d149 = deque([1, 2, 3])
d149.rotate(True)
print(list(d149))
print(deque([1, 2, 3]).index(2, True))

# index start/end 实参: 大数按 ±∞ 钳制, float/str/None 报 slice indices TypeError
def _arg_exc(label, fn):
    try:
        print(label, repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, str(e))


d107 = deque([1, 2, 3])
_arg_exc("dq_big_start", lambda: d107.index(1, 10**100))
_arg_exc("dq_big_neg_end", lambda: d107.index(1, 0, -10**100))
print(deque([1, 2, 3]).index(3, 0, 10**100))
print(deque([1, 2, 3]).index(1, -10**100))
_arg_exc("dq_float", lambda: d107.index(1, 1.5))
_arg_exc("dq_none", lambda: d107.index(1, None))
_arg_exc("dq_str", lambda: d107.index(1, "x"))
_arg_exc("dq_big_type", lambda: d107.index(1, 10**100, 1.5))
