# 职责: ord/chr 与 hex/oct/bin 进制转换
# 比对: same_output


print(ord("A"))              # 65
print(ord("a"))              # 97
print(ord("0"))              # 48
print(chr(65))               # A
print(chr(97))               # a
print(chr(48))               # 0

print(hex(255))              # 0xff
print(hex(16))               # 0x10
print(oct(8))                # 0o10
print(oct(64))               # 0o100
print(bin(5))                # 0b101
print(bin(255))              # 0b11111111

# 错误路径与负数进制
try:
    ord("")
except TypeError as e:
    print("TE1:", e)
try:
    ord("ab")
except TypeError as e:
    print("TE2:", e)
print(hex(-255), oct(-255), bin(-255))

print("done")