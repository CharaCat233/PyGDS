# 类型行为补全测试: bytes / range / dict 视图

# === bytes 是独立类型 ===
b = b"xy"
print(type(b).__name__)
print(b)
print(len(b))
print(b[0], b[1])
print(list(b))
print(b == b"xy", b == "xy")
print(b"abc" + b"d")
print(b"hello"[1:3])
print(b"hello"[::-1])
print(b"a" * 3)
print(120 in b"xy")
print(len(b""))
print(b"" == b"")

# bytes 与 str 不可混用
try:
    b"a" + "b"
except TypeError as e:
    print("concat:", e)

# === range 是独立类型 ===
r = range(5)
print(type(r).__name__)
print(r)
print(len(r))
print(list(r))
print(r[0], r[4], r[-1])
print(range(2, 8), len(range(2, 8)))
print(range(0, 10, 3), list(range(0, 10, 3)))
print(range(10, 0, -3), list(range(10, 0, -3)))
print(range(0), len(range(0)), list(range(0)))
print(range(3) == range(3), range(3) == range(4))
print(3 in range(5), 5 in range(5), 4 in range(0, 10, 2))
print(repr(range(3)), repr(range(0, 10, 2)))
# 切片
print(range(10)[2:5], list(range(10)[2:5]))
print(range(10)[::-1], list(range(5)[::-1]))
print(range(10)[::2])
print(range(10)[-3:])
# range 惰性: 大范围无需展开
print(len(range(1000000)))
# 不可变
try:
    range(3)[0] = 9
except TypeError as e:
    print("assign:", e)
try:
    del range(3)[0]
except TypeError as e:
    print("delete:", e)
try:
    range(1, 2, 0)
except ValueError as e:
    print("step:", e)
# 消费
print(list(reversed(range(3))))
print(sorted(range(3, 0, -1)))
print(max(range(5)), min(range(5)), sum(range(5)))

# === dict 视图可迭代且有 len ===
d = {"a": 1, "b": 2, "c": 3}
print(len(d.keys()), len(d.values()))
print(sorted(d.keys()))
print(sorted(d.values()))
print(list(d.items()))
print("b" in d.keys(), "z" in d.keys())
print(2 in d.values(), 9 in d.values())
print(type(d.keys()).__name__, type(d.values()).__name__)
print(repr(d.keys()))
print(repr(d.values()))
for k in d.keys():
    print("key", k)
for v in d.values():
    print("val", v)
print(d.keys() == d.keys())
print(set(d.keys()) == {"a", "b", "c"})

print("done")
