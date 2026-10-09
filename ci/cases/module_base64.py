# duty: base64 模块 Base16/Base64 编解码 (标准/urlsafe/行包裹, CPython 对齐)
# 比对: same_output
import base64

def show(label, fn):
    try:
        print(label, "OK", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__)

b64 = base64.b64encode(b"hello world")
print("b64e", b64)
print("b64d", base64.b64decode(b64))
print("b64e2", base64.b64encode(b"a"))
print("b64d2", base64.b64decode(base64.b64encode(b"ab")))
print("b64d3", base64.b64decode(base64.b64encode(b"\x00\x01\xff\xfe")))
print("alt", base64.b64encode(b"hi", b"-_"))
print("altd", base64.b64decode(base64.b64encode(b"hi", b"-_"), b"-_"))
print("url", base64.urlsafe_b64encode(b"\xfb\xff\x01"))
print("urld", base64.urlsafe_b64decode(base64.urlsafe_b64encode(b"\xfb\xff\x01")))
print("b16e", base64.b16encode(b"\x01\xab\xff"))
print("b16d", base64.b16decode(base64.b16encode(b"\x01\xab\xff")))
print("eb", base64.encodebytes(b"hello world hello world hello world"))
print("db", base64.decodebytes(base64.encodebytes(b"hello world hello world hello world")))
