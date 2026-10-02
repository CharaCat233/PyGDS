# duty: bytearray 的构造/可变操作/算术/切片赋值与 bytes 互转
# 比对: same_output

ba = bytearray(b"abc")
print(ba)
print(bytearray(), bytearray(3), bytearray([1, 2, 3]))
print(bytearray("hé", "utf-8"))
print(bytearray(range(3)))
print(ba.upper(), ba + b"d", b"d" + ba, ba * 2)
print(ba[1:], ba[1], list(ba), len(ba))
print(ba == b"abc", ba != b"abc", b"b" in ba)
print(ba.index(b"b"), ba.count(b"a"), ba.find(b"c"))
try:
    ba[0] = 300
except ValueError as e:
    print("VE1:", e)
ba[0] = 100
print(ba)
try:
    ba[9] = 1
except IndexError as e:
    print("IE1:", e)
ba[1:3] = b"XY"
print(ba)
ba2 = bytearray(b"abc")
del ba2[0]
print(ba2)
print(ba2.pop(), ba2.pop(0))
ba3 = bytearray(b"abc")
print(ba3.remove(98), ba3)
ba3.append(100)
ba3.extend([101, 102])
ba3.insert(0, 48)
print(ba3)
print(ba3.copy(), ba3.copy() is ba3)
ba3.reverse()
print(ba3)
ba3.clear()
print(ba3, len(ba3))
try:
    ba3.pop()
except IndexError as e:
    print("IE2:", e)
try:
    bytearray(b"abc").remove(300)
except ValueError as e:
    print("VE2:", e)
try:
    bytearray(b"abc").append("x")
except TypeError as e:
    print("TE1:", e)
try:
    bytearray("abc")
except TypeError as e:
    print("TE2:", e)
print(bytearray(b"a'c"))
print(bytearray(b"a-b").split(b"-"))
print(bytearray(b"abc").hex(), bytearray(b"abc").decode())
print(bytearray(b"abc").replace(b"a", b"x"))
print(sorted([bytearray(b"b"), bytearray(b"a")]))
print(min(bytearray(b"cba")))
print(type(bytearray()).__name__)
print(isinstance(bytearray(), bytes), isinstance(bytearray(), bytearray))
try:
    d = {}
    d[bytearray()] = 1
except TypeError as e:
    print("TE3:", e)
try:
    bytearray(b"abc") % b"%d"
except TypeError as e:
    print("TE4:", e)
ba4 = bytearray(b"abc")
ba4 += b"de"
ba4 *= 2
print(ba4)
for b in bytearray(b"ab"):
    print(b)
print(bytes(ba4))
print(ba4.startswith(b"ab"), b"cd" in ba4)
