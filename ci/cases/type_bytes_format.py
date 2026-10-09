# 职责: bytes % 格式化占位符与对齐填充
# 比对: same_output

# bytes % 格式化 (PEP 461, alpha.4, P1-65)
print(b"%d" % 5, b"%i" % -3, b"%x" % 255, b"%X" % 255, b"%o" % 8, b"%u" % 7)
print(b"%f" % 1.5, b"%.2f" % 1.5, b"%e" % 150.0, b"%g" % 1500000.0)
print(b"%s" % b"xyz", b"%b" % b"hi")
print(b"%r" % "a", b"%r" % 5, b"%r" % b"a")
print(b"%a" % "ab", b"%a" % 5)
print(b"%c" % 65, b"%c" % True)
print(b"100%%" % ())
print(b"[%-5d]" % 1, b"[%5d]" % 1, b"[%05d]" % 1)
print(b"[%-5b]" % b"x", b"[%5b]" % b"x")
print(b"abc" % ())
print(b"%(a)s" % {b"a": b"v"}, b"%(n)d" % {b"n": 3})
class B:
    def __bytes__(self):
        return b"proto"

print(b"%b" % B())

# 错误路径: 类型不匹配
try:
    b"%d" % "x"
except TypeError as e:
    print("TE:", e)

# 数值转换实参校验: 字节类/字符串/浮点按 CPython 报 TypeError, 不再静默按 0 (I2-63 连带)
try:
    b"%d" % b"5"
except TypeError as e:
    print("TE-d-bytes:", e)
try:
    b"%d" % bytearray(b"5")
except TypeError as e:
    print("TE-d-ba:", e)
try:
    b"%x" % 1.5
except TypeError as e:
    print("TE-x-float:", e)
try:
    b"%f" % b"5"
except TypeError as e:
    print("TE-f-bytes:", e)
try:
    b"%s" % 5
except TypeError as e:
    print("TE-s-int:", e)
try:
    b"%s" % "x"
except TypeError as e:
    print("TE-s-str:", e)
try:
    b"%c" % 300
except OverflowError as e:
    print("TE-c-overflow:", e)
# 合法数字形态不受影响
print(b"%d" % True, b"%d" % 1.5, b"%x" % 255, b"%f" % 5)
