# str % printf 风格格式化测试

# 基本转换
print("%s is %d years old" % ("Alice", 30))
print("%s" % 3.14)           # 3.14
print("%s" % [1, 2])         # [1, 2]
print("%r" % "str")          # 'str'

# 整数格式
print("%d" % 42)             # 42
print("%d" % 3.7)            # 3 (截断)
print("%x" % 255)            # ff
print("%X" % 255)            # FF
print("%o" % 8)              # 10
print("%c" % 65)             # A

# 浮点格式
print("%f" % 3.14)           # 3.140000
print("%.2f" % 3.14159)      # 3.14
print("%5.2f" % 3.14159)     # " 3.14"
print("%.2e" % 12345.678)    # 1.23e+04
print("%g" % 12345.678)      # 12345.7
print("%g" % 1000000)        # 1e+06

# 宽度与对齐
print("%05d" % 42)           # 00042
print("%5d" % 42)            # "   42"
print("%-5d|" % 42)          # "42   |"
print("%10s|" % "hi")        # "        hi|"
print("%-10s|" % "hi")       # "hi        |"

# 符号
print("%+d" % 5)             # +5
print("%+d" % -5)            # -5
print("% d" % 5)             # " 5"
print("% d" % -5)            # -5

# 转义与多值
print("%d%%" % 50)           # 50%
print("%s %s %s" % (1, 2, 3))  # "1 2 3"
print("%s: %d" % ("count", 5)) # "count: 5"

# 字符串精度截断
print("%.3s" % "abcdef")     # abc

# 元组作为单个值需要双重括号
t = (1, 2)
print("%s" % (t,))           # (1, 2)

print("done")
