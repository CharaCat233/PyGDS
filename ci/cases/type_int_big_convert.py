# 职责: 任意精度 int 的字面量、串互转与数值转换 (P0-13)
# 比对: same_output

# 字面量形态: 十进制下划线与各进制前缀
print(123456789012345678901234567890)
print(1_000_000_000_000_000_000_000_000)
print(0xFFFFFFFFFFFFFFFFFFFFFFFF)
print(0o777777777777777777777)
print(0b1 << 80)
print(-9223372036854775808)
print(0)

# 字面量驻留身份 (同一字面量共享实例; 表达式如 10**30 不在驻留范围)
x = 1000000000000000000000000000000
y = 1000000000000000000000000000000
print(x is y)

# int() 串转换 (超 int64 精确升级)
print(int("9" * 30))
print(int("-123456789012345678901234567890"))
print(int("0x" + "f" * 20, 16))
print(int("zz", 36))
print(int("10101010101010101010101010101", 2))
print(int("+5_000_000_000_000_000_000"))

# float 的精确整数截断 (double 的十进制展开)
print(int(1e30))
print(int(-1e30))
print(int(1e19))
print(int(1234.5678))
print(int(2 ** 68 + 0.9))

# round: 大数与浮点
print(round(1e30))
print(round(1e19))
print(round(2 ** 70, -5))
print(round(123456789012345678901234567890, -10))
print(round(-(123456789012345678901234567890), -10))
print(round(2.5))
print(round(-0.5, -1))

# float() 与越界报错
print(float(10 ** 30))
print(float(2 ** 70))
try:
    print(float(10 ** 400))
except OverflowError as e:
    print("OE:", e)

# abs / str / repr
print(abs(-(10 ** 30)))
print(abs(9223372036854775807 + 1))
print(str(10 ** 30))
print(repr(-(10 ** 30)))
print(type(10 ** 30).__name__, isinstance(10 ** 30, int))

# to_bytes 大数形态
print((10 ** 15).to_bytes(8, "big").hex())
print((2 ** 70).to_bytes(16, "little").hex()[:8])
print("done")
