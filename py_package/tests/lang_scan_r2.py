# 第二轮扫描修复: split / math / reversed / format 字段 / bytes / except-as / center
print("a,b,c".split(",", 0), "a,b,c".split(",", 1), " a b ".split(None, 0))
import math
print(math.floor(2.7), math.sqrt(16))
try:
    math.sqrt(-1)
except ValueError as e:
    print("VE:", e)
try:
    math.log(0)
except ValueError as e:
    print("LOG:", e)
r = reversed([1, 2, 3])
print(list(r), list(r))
print(type(r).__name__)
print(list(reversed("ab")), list(reversed((1, 2))))
print(list(reversed({"a": 1, "b": 2})))
print("{0.real} {n.v}".format(3, n=2 + 0 * 1) if False else "{0.real}".format(3))
class N:
    v = "attr-val"
print("{m.v}".format(m=N()))
print(b"abc" < b"abd", b"abc" <= b"abc", b"abd" > b"abc")
print(bytes(range(3)))
try:
    raise ValueError("v")
except ValueError as e:
    pass
try:
    print(e)
except NameError:
    print("as-deleted")
try:
    raise 1
except TypeError as err:
    print("TE:", err)
print("ab".center(5, "-"), "abc".center(6))
try:
    "ab".center(5, "**")
except TypeError as e:
    print("FILL")
