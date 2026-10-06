# duty: 大数 range 的任意精度语义: 惰性构造 / len 越界 OverflowError / 大数下标与负下标 / 成员判定 / 切片 / 反向 / 等值与真值 / start-stop-step 属性
# 比对: same_output
# 锚定: CPython 3.12
r = range(10**30, 10**30 + 5)
print("A", r, len(r))
print("B", r[0], r[4], r[-1])
print("C", 10**30 in r, 10**30 + 9 in r)
print("D", list(r))
try:
    list(range(10**30))
except OverflowError as e:
    print("E", e)
try:
    len(range(10**30))
except OverflowError as e:
    print("F", e)
print("G", list(reversed(r)))
print("H", range(10**30, 10**30 + 9, 3)[2], range(10**30)[10**20])
s = range(0, 10**30, 7)
print("I", s[123456789], 10**30 + 7*3 in s)
print("J", r == range(10**30, 10**30 + 5), r == range(0, 5), r != range(0, 5))
for x in range(10**30, 10**30 + 3):
    print("K", x)
print("L", list(range(-10**30, -10**30 - 6, -2)))
print("M", range(10)[10**30:], range(10)[10**30 - 3:], list(range(10)[10**30 - 3:]))
print("N", bool(range(10**30)), bool(range(0, 10**30, -1)))
print("O", range(10**30).start, range(10**30).step)
print("P", list(range(10**30, 10**30 - 6, -2)))
print("Q", range(10**30, 10**30, 3) == range(5, 5, -7))
print("R", repr(range(10**30, 10**30 + 5, 2)))
print("S", len(range(0, -10**30, 2)))
try:
    len(range(0, 10**30, 3))
except OverflowError as e:
    print("T", e)
print("U", range(10**30 + 10**15)[5**20])
print("V", range(0, 10**30, 10**28)[-1], list(range(0, 10**30, 10**28)))
try:
    range(1, 2, 0)
except ValueError as e:
    print("W", e)
print("X", type(range(10**30)).__name__, isinstance(range(10**30), range))
big = range(-(10**30), -(10**30) + 4, 2)
print("Y", list(big), big[1], len(big))
print("Z", 10**30 - 1 in range(10**30), 10**30 - 1 not in range(10**30, 10**30 + 5))
