# 职责: 编码名别名与大小写归一 (encode/decode/bytes 构造)
# 比对: same_output

print("abc".encode("UTF8"))
print("abc".encode("utf_8"))
print("abc".encode("US-ASCII"))
print("abc".encode("latin1"), "é".encode("LATIN-1"), "é".encode("ISO-8859-1"))
print(b"abc".decode("UTF8"), b"\xe9".decode("latin1"), b"abc".decode("Ascii"))
print(bytes("abc", "utf-8"), bytes("abc", "UTF8"))
print(bytes("é", "latin1"))
try:
    print("abc".encode("bogus"))
except LookupError as e:
    print("LE", e)
try:
    print(bytes("abc", "bogus"))
except LookupError as e:
    print("LE2", e)
