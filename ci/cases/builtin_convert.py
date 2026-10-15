# 职责: int/float/bool 转换与混合运算结果类型
# 比对: same_output


n1 = int(50)
n2 = 50
m1 = float(2.0)
m2 = 2.0
t1 = bool(True)
t2 = True
f1 = bool(False)
f2 = False
bd = bool()

print(n1 == 50)
print(n1 == int(50))
print(n1 == int(50.0))
print(n2 == 50)
print(n2 == int(50))
print(n2 == int(50.0))

print(m1 == 2.0)
print(m1 == float(2.0))
print(m1 == float(2))
print(m2 == 2.0)
print(m2 == float(2.0))
print(m2 == float(2))

print(t1 == True)
print(t2 == True)
print(f1 == True)
print(f2 == True)
print(bd == True)
print(t1 == bool(True))
print(t2 == bool(True))
print(f1 == bool(True))
print(f2 == bool(True))
print(bd == bool(True))
print(t1 == False)
print(t2 == False)
print(f1 == False)
print(f2 == False)
print(bd == False)
print(t1 == bool(False))
print(t2 == bool(False))
print(f1 == bool(False))
print(f2 == bool(False))
print(bd == bool(False))
print(t1 == bool())
print(t2 == bool())
print(f1 == bool())
print(f2 == bool())
print(bd == bool())

print(10 + 20)
print(10 + int(20))
print(int(10) + 20)
print(int(10) + int(20))

res = 10 + 10
print(res, type(res))  # int + int
res = 10.0 + 10.0
print(res, type(res))  # float + float
res = 10 + 10.0
print(res, type(res))  # int + float
res = 10.0 + 10
print(res, type(res))  # float + int

res = 10 - 10
print(res, type(res))  # int - int
res = 10.0 - 10.0
print(res, type(res))  # float - float
res = 10 - 10.0
print(res, type(res))  # int - float
res = 10.0 - 10
print(res, type(res))  # float - int

res = 10 * 10
print(res, type(res))  # int * int
res = 10.0 * 10.0
print(res, type(res))  # float * float
res = 10 * 10.0
print(res, type(res))  # int * float
res = 10.0 * 10
print(res, type(res))  # float * int

res = 10 / 10
print(res, type(res))  # int / int
res = 10.0 / 10.0
print(res, type(res))  # float / float
res = 10 / 10.0
print(res, type(res))  # int / float
res = 10.0 / 10
print(res, type(res))  # float / int

res = 10 // 10
print(res, type(res))  # int // int
res = 10.0 // 10.0
print(res, type(res))  # float // float
res = 10 // 10.0
print(res, type(res))  # int // float
res = 10.0 // 10
print(res, type(res))  # float // int

res = 10 % 10
print(res, type(res))  # int % int
res = 10.0 % 10.0
print(res, type(res))  # float % float
res = 10 % 10.0
print(res, type(res))  # int % float
res = 10.0 % 10
print(res, type(res))  # float % int

res = 10**10
print(res, type(res))  # int ** int
res = 10.0**10.0
print(res, type(res))  # float ** float
res = 10**10.0
print(res, type(res))  # int ** float
res = 10.0**10
print(res, type(res))  # float ** int

# int(bytes) 实参; bin/oct/hex 接受 bool (bool 是 int 子类)
print(int(b"12"))
print(int(b" 12 "))
print(int(b"ff", 16))
try:
    int(b"12.5")
except ValueError as e:
    print("VE:", str(e))
print(bin(True))
print(oct(True))
print(hex(True))
print(bin(10))
try:
    bin(1.5)
except TypeError as e:
    print("TE:", str(e))
try:
    hex("10")
except TypeError as e:
    print("TE2:", str(e))


# int() 解析 Nd 十进制数字 (阿拉伯-印度数字等 Unicode 数字)
def _show_nd(label, fn):
    try:
        print(label, "OK", fn())
    except Exception as e:
        print(label, type(e).__name__, str(e))


_show_nd("nd_10", lambda: int("\u0661\u0662\u0663"))
_show_nd("nd_base10", lambda: int("\u0661\u0662\u0663", 10))
_show_nd("nd_base16", lambda: int("\u0661\u0662\u0663", 16))
_show_nd("nd_neg", lambda: int("-\u0661\u0662\u0663"))
_show_nd("nd_ws", lambda: int("  \u0661\u0662\u0663  "))
_show_nd("nd_mix", lambda: int("1\u0669"))
_show_nd("nd_ascii", lambda: int("123"))
_show_nd("nd_fullwidth", lambda: int("\uff11\uff12\uff13"))
