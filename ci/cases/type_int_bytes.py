# 职责: int.to_bytes 二补码与 from_bytes 大数
# 比对: same_output

# to_bytes(signed=True) 负数此前输出幅值字节而非二补码
print((-1).to_bytes(2, "big", signed=True))
print((-1).to_bytes(2, "little", signed=True))
print((-128).to_bytes(1, "big", signed=True))
print((-127).to_bytes(1, "big", signed=True))
print((-300).to_bytes(2, "big", signed=True))
print((-2 ** 63).to_bytes(8, "big", signed=True))
print((-2 ** 64).to_bytes(9, "big", signed=True))
print((-1).to_bytes(1, "big", signed=True))

# 非负与无符号语义保持
print((0).to_bytes(2, "big"))
print((255).to_bytes(1))
print((256).to_bytes(2))
print((127).to_bytes(1, "big", signed=True))
print((2 ** 64).to_bytes(9, "big"))
print((2 ** 64 - 1).to_bytes(8, "big"))

# 越界报错: 幅值超容量 OverflowError (边界值放行)
try:
    print((128).to_bytes(1, "big", signed=True))
except OverflowError as e:
    print("OE", str(e))

try:
    print((-129).to_bytes(1, "big", signed=True))
except OverflowError as e:
    print("OE", str(e))

try:
    print((256).to_bytes(1))
except OverflowError as e:
    print("OE", str(e))

try:
    print((2 ** 64).to_bytes(8))
except OverflowError as e:
    print("OE", str(e))

# 负值无符号报错
try:
    print((-1).to_bytes(2, "big"))
except OverflowError as e:
    print("OE", str(e))

# byteorder 校验前置 (此前负数先按 OverflowError)
try:
    print((1).to_bytes(2, "middle"))
except ValueError as e:
    print("VE", str(e))

# 负 length 报错
try:
    print((1).to_bytes(-1))
except ValueError as e:
    print("VE", str(e))

# from_bytes 超过 8 字节此前按 int64 移位溢出回绕为 0
print(int.from_bytes(b"\x01" + b"\x00" * 8, "big"))
print(int.from_bytes(b"\x01" + b"\x00" * 9, "big"))
print(int.from_bytes(b"\xff" * 9, "big"))
print(int.from_bytes(b"\x00\x00\x00\x00\x00\x00\x00\x00\x01", "big"))
print(int.from_bytes(b"\xff\xff", "big", signed=True))
print(int.from_bytes(b"\x80", "big", signed=True))
print(int.from_bytes(b"\xff" * 9, "big", signed=True))
print(int.from_bytes((2 ** 100).to_bytes(13, "little"), "little"))
print(int.from_bytes(b"", "big"))
print(int.from_bytes((2 ** 200).to_bytes(26, "big"), "big"))
