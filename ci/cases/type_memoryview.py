# duty: memoryview 的构造/下标/切片/只读与可写透传/tobytes/cast/release
# 比对: same_output

mv = memoryview(b"abc")
print(len(mv))
print(mv[1])
print(mv[1:].tobytes())
print(mv.tobytes())
print(mv.hex())
print(mv.readonly)
print(mv.obj)
print(mv.nbytes, mv.itemsize, mv.format, mv.ndim)
print(mv.shape)
print(list(mv))
print(mv == memoryview(b"abc"))
print(mv == b"abc")
print(bool(memoryview(b"")), bool(memoryview(b"x")))
print(bytes(mv))
ba = bytearray(b"ab")
mv2 = memoryview(ba)
mv2[0] = 100
print(ba)
try:
    memoryview(b"ab")[0] = 1
except TypeError as e:
    print("TE1:", e)
try:
    memoryview("abc")
except TypeError as e:
    print("TE2:", e)
try:
    memoryview(b"ab")[5]
except IndexError as e:
    print("IE1:", e)
mvr = memoryview(b"ab")
mvr.release()
try:
    len(mvr)
except ValueError as e:
    print("VE1:", e)
print(memoryview(bytearray(b"ab")).tobytes())
print(memoryview(b"ab").cast("B")[0])

# 显式步长切片 (此前负步长触发引擎级 SCRIPT ERROR, 非平凡步长按长度 0 处理)
# CPython 1-D B 格式视图支持任意步长, 负步长反转内容
print(bytes(memoryview(b"abc")[1:2:-1]))
print(bytes(memoryview(b"abc")[::-1]))
print(bytes(memoryview(b"abc")[::2]))
print(bytes(memoryview(b"abc")[1:]))
print(len(memoryview(b"abc")[3:1]))
print(bytes(memoryview(b"abc")[3:1]))
print(memoryview(b"abc")[1])
print(bytes(memoryview(b"abc")[0:3:2]))
print(bytes(memoryview(b"abcde")[::-2]))
print(bytes(memoryview(b"abcde")[4:0:-1]))

# memoryview 下标接受 bool (bool 是 int 子类)
print(memoryview(b"abc")[True])
