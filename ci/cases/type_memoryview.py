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

# tolist/toreadonly 与 cast 多字节原生格式 (little-endian)
def _mv(label, fn):
    try:
        print(label, fn())
    except Exception as e:
        print(label, type(e).__name__, e)


_mv("tolist", lambda: memoryview(b"ab").tolist())
_mv("tolist_empty", lambda: memoryview(b"").tolist())
_mv("cast_H", lambda: memoryview(b"ab").cast("H").tolist())
_mv("cast_I", lambda: memoryview(b"abcd").cast("I").tolist())
_mv("cast_Q", lambda: memoryview(b"abcdefgh").cast("Q").tolist())
_mv("cast_i_signed", lambda: memoryview(b"\x01\x00\x00\x00\x02\x00\x00\x00").cast("i").tolist())
_mv("cast_len", lambda: len(memoryview(b"abcd").cast("H")))
_mv("cast_itemsize", lambda: (memoryview(b"ab").cast("H").itemsize, memoryview(b"abcd").cast("I").itemsize))
_mv("cast_nbytes", lambda: memoryview(b"ab").cast("H").nbytes)
_mv("cast_getitem", lambda: memoryview(b"ab").cast("H")[0])
_mv("cast_back", lambda: memoryview(b"abcd").cast("H").cast("B").tolist())
_mv("cast_tobytes", lambda: memoryview(b"ab").cast("H").tobytes())
_mv("cast_ba", lambda: memoryview(bytearray(b"ab")).cast("H").tolist())
_mv("cast_ro", lambda: (memoryview(b"ab").cast("H").readonly, memoryview(bytearray(b"ab")).cast("H").readonly))
_mv("tolist_iter", lambda: list(memoryview(b"ab").cast("H")))
_mv("toreadonly_ro", lambda: memoryview(bytearray(b"ab")).toreadonly().readonly)
_mv("toreadonly_val", lambda: memoryview(bytearray(b"ab")).toreadonly()[0])
_mv("cast_at", lambda: memoryview(b"ab").cast("@H").tolist())
_mv("cast_badfmt", lambda: memoryview(b"ab").cast("x"))
_mv("cast_mod", lambda: memoryview(b"abc").cast("H"))
_mv("cast_float_mod", lambda: memoryview(b"ab").cast("f"))

# 多字节格式下标赋值: little-endian 写入, 值域与类型按格式校验 (CPython 同)
def _mv_set_h(ba, v):
    mv = memoryview(ba).cast("H")
    mv[0] = v
    return bytes(ba)


def _mv_set_i(ba, v):
    mv = memoryview(ba).cast("I")
    mv[0] = v
    return bytes(ba)


def _mv_set_b(ba, sl, src):
    mv = memoryview(ba)
    mv[sl] = src
    return bytes(ba)


def _mv_set_h_slice(ba, src):
    mv = memoryview(ba).cast("H")
    mv[0:2] = src
    return bytes(ba)


_mv("h_set", lambda: _mv_set_h(bytearray(b"ab"), 65535))
_mv("h_over", lambda: _mv_set_h(bytearray(b"ab"), 65536))
_mv("h_neg", lambda: _mv_set_h(bytearray(b"ab"), -1))
_mv("h_float", lambda: _mv_set_h(bytearray(b"ab"), 1.5))
_mv("i_set", lambda: _mv_set_i(bytearray(b"abcd"), 1))
def _mv_set_ro(ba):
    mv = memoryview(ba).toreadonly()
    mv[0] = 1
    return bytes(ba)


_mv("ro_set", lambda: _mv_set_ro(bytearray(b"ab")))

# 字节视图切片赋值 (结构校验; 多字节格式要求同格式同元素数结构)
_mv("b_slice", lambda: _mv_set_b(bytearray(b"abcd"), slice(0, 2), b"xy"))
_mv("b_slice_bad", lambda: _mv_set_b(bytearray(b"abcd"), slice(0, 2), b"xyz"))
_mv("b_slice_step", lambda: _mv_set_b(bytearray(b"abcd"), slice(0, 4, 2), b"xy"))
_mv("h_slice_bytes", lambda: _mv_set_h_slice(bytearray(b"abcd"), b"wxyz"))


def _mv_set_h_slice_mv(ba, src_mv):
    mv = memoryview(ba).cast("H")
    mv[0:2] = src_mv
    return bytes(ba)


_mv("h_slice_mv", lambda: _mv_set_h_slice_mv(bytearray(b"abcd"), memoryview(bytearray(b"wxyz")).cast("H")))
