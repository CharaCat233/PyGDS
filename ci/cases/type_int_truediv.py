# 职责: int/int 真除单次舍入与除零
# 比对: same_output

# int/int 真除此前两侧各自转 double 再相除 (双舍入)
# 改为 54~55 位整商 + 粘位余数一次舍入 (CPython long_true_divide)
print((2 ** 53 + 1) / 3)
print((2 ** 53 + 1) / 3.0)
print((2 ** 60) / 3)
print((2 ** 60 + 1) / 3)
print((2 ** 64) / 7)
print((2 ** 100) / 3)
print((10 ** 30) / 3)
print(10 ** 30 / 3)
print(1 / 3)
print(7 / 2)
print(-7 / 2)
print(7 / -2)
print(-7 / -2)
print(2 ** 53 / 1)
print((2 ** 53 - 1) / 1)

# 快路径 (|值| < 2^53) 保持宿主除法 (单次正确舍入)
print(9007199254740991 / 2)
print(123456789 / 7)

# 大整数除以零此前静默 inf (零判断被分支跳过), 改为 ZeroDivisionError
try:
    print(10 ** 100 / 0)
except ZeroDivisionError as e:
    print("ZDE", str(e))

try:
    print(-(10 ** 100) / 0)
except ZeroDivisionError as e:
    print("ZDE", str(e))

try:
    print(10 / 0)
except ZeroDivisionError as e:
    print("ZDE", str(e))

# 真除结果超 double 上界报 OverflowError (CPython)
try:
    print((10 ** 400) / 1)
except OverflowError as e:
    print("OE", str(e))
