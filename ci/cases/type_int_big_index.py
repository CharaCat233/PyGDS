# 职责: 任意精度 int 在索引位边界的收敛 (P0-13, CPython Py_ssize_t 同构)
# 比对: same_output

big = 10 ** 30
lst = [1, 2, 3]
s = "abcdef"
t = (4, 5, 6)

# 序列下标: 大数下标报 IndexError (CPython 同文案)
try:
    print(lst[big])
except IndexError as e:
    print("IE:", e)
try:
    print(lst[big] == 0)
except IndexError as e:
    print("IE2:", e)
try:
    print(s[big])
except IndexError as e:
    print("IE3:", e)
try:
    print(t[big])
except IndexError as e:
    print("IE4:", e)

# 切片分量: 大数按钳制语义 (CPython 切片不报错)
print(lst[big:])
print(lst[:big])
print(lst[-big:])
print(lst[1:big])
print(s[big:])
print(s[:big])
print(t[big:])

# 序列重复计数: 大数报 OverflowError
try:
    print("a" * big)
except OverflowError as e:
    print("OE:", e)
try:
    print([1] * big)
except OverflowError as e:
    print("OE2:", e)
try:
    print((1,) * big)
except OverflowError as e:
    print("OE3:", e)

# range 参数为索引位: PyGDS 收敛为 int64 (既定限制, 与 CPython 惰性构造不同, 不做双端比对)
# 此处仅覆盖 range 与合法大数的可通行形态
print(list(range(3)))

# str 宽度参数
try:
    print("ab".center(big))
except OverflowError as e:
    print("OE4:", e)
try:
    print("ab".ljust(big))
except OverflowError as e:
    print("OE5:", e)

# chr / bytes 的分配与码点边界
try:
    print(chr(big))
except OverflowError as e:
    print("OE6:", e)
try:
    print(bytes(big))
except OverflowError as e:
    print("OE7:", e)

# 巨移位: 结果位数不可控 (巨幂的 MemoryError 属资源相关行为, 不做双端断言)
try:
    print(1 << (2 ** 70))
except OverflowError as e:
    print("OE8:", e)

# to_bytes 长度不足
try:
    print((10 ** 30).to_bytes(4, "big"))
except OverflowError as e:
    print("OE9:", e)
print((10 ** 30).to_bytes(16, "big")[:4].hex())
print("done")
