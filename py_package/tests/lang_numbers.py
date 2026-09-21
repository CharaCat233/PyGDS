# 数字字面量测试: 进制 / 下划线 / 科学计数法

# 十六进制
print(0x1F)            # 31
print(0X1f)            # 31
print(0xFF)            # 255
print(0x10)            # 16
print(0x0)             # 0

# 八进制
print(0o17)            # 15
print(0o10)            # 8
print(0O7)             # 7

# 二进制
print(0b101)           # 5
print(0b1111)          # 15
print(0B0)             # 0

# 下划线分隔
print(1_000)           # 1000
print(1_000_000)       # 1000000
print(1_2_3)           # 123
print(0xFF_FF)         # 65535
print(1_000.5)         # 1000.5

# 科学计数法
print(1e3)             # 1000.0
print(1.5e2)           # 150.0
print(2.5e-2)          # 0.025
print(1E1)             # 10.0

# 混合运算
print(0x10 + 0o10 + 0b10 + 2)  # 16 + 8 + 2 + 2 = 28
print(0xFF - 0xF)      # 240
print(0b1111 * 2)      # 30
print(1_000 // 3)      # 333

print("done")
