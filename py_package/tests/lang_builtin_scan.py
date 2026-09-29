# 内建扩展: 数值方法 / bytes.fromhex / 哈希不变量 / 编码族 / translate / iter 两参
print((2).bit_length(), (-7).bit_length(), (1).real, (1).imag, (5).numerator, (5).denominator)
print(1.0.is_integer(), (2.5).is_integer(), (2.5).real, (2.5).imag)
print(bytes.fromhex("4142"), bytes.fromhex("41 42"), bytes.hex(b"AB"))
print(hash(1) == hash(1.0), hash(True) == hash(1), hash((1, 2)) == hash((1, 2)))
d = {(1, 2): "a"}
print(d[(1, 2)], (1, 2) in d)
s = "h" + chr(233) + "llo"
print(repr(s.encode("utf-8")))
try:
    s.encode("ascii")
except UnicodeEncodeError as e:
    print("UE")
print(repr(s.encode("ascii", "replace")), repr(s.encode("ascii", "ignore")))
bad = bytes([0xff, 0xfe])
try:
    bad.decode("ascii")
except UnicodeDecodeError as e:
    print("UD")
print(repr(bad.decode("utf-8", "replace")), repr(bad.decode("latin-1")))
print(repr("abc".translate(str.maketrans("abc", "xyz"))))
print(repr("abc".translate(str.maketrans("a", "x", "c"))))
print(repr("abc".translate({ord("a"): "A"})))
print("42".zfill(5), "-42".zfill(5), "+42".zfill(6))
n = 0
def cnt():
    global n
    n += 1
    return n
print(list(iter(cnt, 4)), list(iter(lambda: "x", "x")))
