# 职责: int.to_bytes 类级未绑定调用的溢出通道与长度边界
# 比对: same_output

print((255).to_bytes(2, "big"))
print(int.to_bytes(1, 1, "big"))
try:
    print(int.to_bytes(256, 1, "big", signed=False))
except OverflowError as err:
    print("oe:", err)
try:
    print((256).to_bytes(1, "big", signed=False))
except OverflowError as err:
    print("oe2:", err)
try:
    print(int.to_bytes(-1, 1, "big", signed=False))
except OverflowError as err:
    print("oe3:", err)
print(int.to_bytes(0, 0, "big", signed=True))
print(int.from_bytes(b"\x01\x00", "little"))
print(int.from_bytes(b"\xff", "big", signed=True))
try:
    print(int.from_bytes(b"\xff", "x"))
except ValueError as err:
    print("ve:", err)
