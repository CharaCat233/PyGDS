# 职责: 任意精度 int 的负数位运算、移位与哈希 (P0-13, CPython 无限二补数语义)
# 比对: same_output

a = 0x123456789ABCDEF0123456789
b = -0xFEDCBA9876543210FEDCBA
print(a & b)
print(a | b)
print(a ^ b)
print(~a)
print(~b)

# 二补数边界: -1 与 0 的位运算
print(-1 & (10 ** 30))
print(-1 | (10 ** 30))
print(-1 ^ (10 ** 30))
print(0 & -(10 ** 30))
print(-1 ^ -(10 ** 30))

# 移位: 跨 limb 边界与负数 floor 语义
print(1 << 100)
print((10 ** 30) << 5)
print((10 ** 30) >> 5)
print(-1 >> 100)
print(-(10 ** 30) >> 3)
print(-(10 ** 30) >> 100)
print((2 ** 64) << 3)
print((2 ** 64) >> 3)

# 右移的向负无穷取整
print(-7 >> 1)
print(-(10 ** 30) >> 1)
print((10 ** 30 - 1) >> 1)

# 取反的符号翻转
print(~(10 ** 30))
print(~(-(10 ** 30)))
print(~~(10 ** 30))

# 哈希: CPython 的模 2^61-1 算法, 快慢路径同哈希
print(hash(-1))
print(hash(0))
print(hash(2 ** 64))
print(hash(10 ** 30))
print(hash(2 ** 61 - 1))
print(hash(-(2 ** 61 - 2)))

# 大数作字典键与集合成员 (等值同键: 大数与同值 int64 互查)
d = {10 ** 30: "big", 5: "small"}
print(d[10 ** 30])
print(d[5])
s = {10 ** 30, 2 ** 70, 5}
print(sorted(s)[0] == 5, 10 ** 30 in s, 2 ** 70 in s)

# 进制串
print(hex(10 ** 30))
print(oct(-(2 ** 64)))
print(bin(2 ** 70))
print(hex(-255))

# 位方法
print((10 ** 30).bit_length())
print((2 ** 70).bit_length())
print((-(2 ** 70) - 1).bit_length())
print((10 ** 30).bit_count())
print("done")
