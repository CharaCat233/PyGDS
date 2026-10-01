# 职责: round 银行家舍入的二进制精确性
# 比对: same_output

# round 的二进制精确银行家舍入 (P2-25)
print(round(2.675, 2))
print(round(0.5))
print(round(1.5))
print(round(2.5))
print(round(-0.5))
print(round(-1.5))
print(round(2.5, 0))
print(round(1234, -2))
print(round(1239, -2))
print(round(1250, -2))
print(round(1e308, 2))
print(round(0.125, 2))
print(round(0.375, 2))
print(round(-2.675, 2))
print(round(0.15, 1))
print(round(5, 2))
print(round(1234.5678, -2))
print(round(-0.0001, 2))
print(round(0.4, 0))
print(round(12345, -1))
print(round(15, -1))
print(round(25, -1))
print(round(-15, -1))
print(round(12350, -1))
print(round(2 ** 52 + 1.0))
print(int(round(2.675, 2) * 100) == 267)
# 零值与负零: 返回值保留符号, 无 ndigits 时转为 int
print(round(0.0, 6))
print(round(0.0))
print(round(-0.0, 2))
print(round(-0.0, 0))
print(round(-0.0))
print(round(-0.0, -1))
print(round(0.0, -3))
# 返回类型: 带 ndigits 的 float 入参返回 float, 无 ndigits 返回 int
print(type(round(2.5, 0)).__name__)
print(type(round(2.5)).__name__)
print(type(round(1234.5678, -2)).__name__)
print(round(2.5, 0) == 2.0)
# 超大 ndigits 与纯小数
print(round(2.718281828459045, 7))
print(round(0.1, 1))
print(round(-0.000000001, 10))
# 错误路径: 不可 round 的类型
try:
    round("a")
except TypeError as e:
    print("TE:", type(e).__name__)

print("done")