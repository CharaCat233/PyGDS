# 职责: bytes 构造形态与 decode/hex/split 等方法
# 比对: same_output


b = b"hello"
print(b.decode())
print(b.hex())
print(b"ABC".lower())
print(b"abc".upper())
print(b"ab".title())
print(b" x ".strip())
print(b"a,b,c".split(b","))
print(b"aaa".replace(b"a", b"b"))
print(b"hello".find(b"ll"))
print(b"hello".index(b"l"))
print(b"hello".count(b"l"))
print(b"abc".startswith(b"ab"))
print(b"abc".endswith(b"c"))
print(b"-".join([b"a", b"b"]))
print(bytes(3))
print(bytes([104, 105]))
print(bytes("hi", "utf-8"))
print(bytes(b"hi"))
print("hi".encode())
print(len(bytes(3)))

# bytes 检索族负 start/大数 end (此前负 start 丢失语义, 大数 end 触发引擎错误)
print(b"abc".find(b"a", -1))
print(b"abc".count(b"a", -2))
print(b"abc".find(b"a", 10**100))
print(b"abc".find(b"a", 0, 100))
print(b"abc".find(b"c", -1))
print(b"abc".count(b"b", 1))
print(b"abc".count(b"a", -3))
print(b"abc".find(b"b", 1, 2))
print(b"abc".find(b"b", 1, 1))
print(b"abc".find(b"", 2))
print(b"abc".count(b""))
print(b"abc".rfind(b"", 1))
print(bytearray(b"abc").find(b"a", -1))
print(bytearray(b"abc").count(b"a", -2))
print(b"abc".find(b"a", -100))
print(b"abc".find(b"a", 100))

# bytes.replace 空 old 展开 (此前主循环对空 old 不前进挂死进程)
# CPython 在相邻位置之间插入: b"abc".replace(b"", b"-") == b"-a-b-c-"
print(b"abc".replace(b"", b"-"))
print(b"abc".replace(b"", b"-", 2))
print(b"abc".replace(b"", b""))
print(b"".replace(b"", b"x"))
print(b"abc".replace(b"a", b"x"))
print(b"abc".replace(b"", b"-", 0))
# 非法实参 (str) 此前被静默按空处理, 应报 TypeError
try:
    b"abc".replace("x", b"y")
except TypeError as e:
    print("TE:", e)
try:
    b"abc".find("x")
except TypeError as e:
    print("TE2:", e)
try:
    b"abc".startswith("x")
except TypeError as e:
    print("TE3:", e)
try:
    b" a".strip("a")
except TypeError as e:
    print("TE4:", e)

# bytearray 负索引赋值 (读路径已有归一, 写路径此前报 IndexError)
bb = bytearray(b"abc")
bb[-1] = 9
print(bytes(bb))
print(bb[-1])
bb2 = bytearray(b"abc")
bb2[-3] = 65
print(bytes(bb2))
try:
    bb3 = bytearray(b"ab")
    bb3[-3] = 1
except IndexError as e:
    print("IE:", str(e))

# bytes.center 奇偶校正 (此前恒反向分配)
print(b"ab".center(5))
print(b"ab".center(6))
print(b"ab".center(5, b"x"))
print(b"ab".center(1))
print(b"a".center(4))
print(bytearray(b"ab").center(5))


# bytes.join 校验元素类型 (CPython: expected a bytes-like object)
try:
    b"-".join(["a"])
except TypeError as e:
    print("TE-bjoin:", str(e))
print(b"-".join([b"a", b"b"]))
# bytes 的 int 语义 (find/count/index/rfind/contains 接受 0-255 字节值)
print(b"abc".find(98))
print(b"abcabc".rfind(98))
print(98 in b"abc")
print(True in b"abc")
print(b"bc" in b"abc")
try:
    "a" in b"abc"
except TypeError as e:
    print("TE-in:", str(e))
try:
    256 in b"abc"
except ValueError as e:
    print("VE-in:", str(e))
try:
    bytes("abc")
except TypeError as e:
    print("TE-bytes:", str(e))
print(bytes("abc", "utf-8"))
try:
    bytes("é", "ascii")
except UnicodeEncodeError as e:
    print("UEE:", str(e))
print(b"abcabc".count(98))
print(b"abcabc".index(98, 1))
try:
    b"abc".find(256)
except ValueError as e:
    print("VE-find:", str(e))
print(b"abc".find(b"bc"))

# bytes 构造接受 bool (bool 是 int 子类)
print(bytes([True]))
print(bytes([True, 0, False]))

# ljust/hex/fromhex 实参校验
try:
    b"a".ljust(5, b"xy")
except TypeError as e:
    print("TE-ljust:", str(e)[:40])
print(b"a".ljust(3, b"x"))
try:
    b"ab".hex(sep="ab")
except ValueError as e:
    print("VE-hex:", str(e)[:40])
print(b"ab".hex(sep="-"))
print(bytes.fromhex("61\t62"))
try:
    bytes.fromhex("az")
except ValueError as e:
    print("VE-fh:", str(e)[:60])
