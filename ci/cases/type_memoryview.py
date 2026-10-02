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
