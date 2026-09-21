# int(str, base) 进制转换测试

# 显式进制
print(int("ff", 16))            # 255
print(int("FF", 16))            # 255
print(int("101", 2))            # 5
print(int("17", 8))             # 15
print(int("z", 36))             # 35
print(int("123", 10))           # 123

# base=0 按前缀自动识别
print(int("0x1f", 0))           # 31
print(int("0o17", 0))           # 15
print(int("0b101", 0))          # 5
print(int("42", 0))             # 42 (无前缀按十进制)

# 带符号
print(int("-ff", 16))           # -255
print(int("+10", 2))            # 2

# 与进制前缀一起显式指定
print(int("0x10", 16))          # 16

# 数字直接转换不受影响
print(int(42))                  # 42
print(int(3.9))                 # 3
print(int(True))                # 1

print("done")
