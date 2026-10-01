# 职责: 64 位整数边界、移位与溢出报错类型
# 比对: same_output

# 整数边界与移位语义 (P0-13)
def check(label, fn):
    try:
        print(label, fn())
    except Exception as e:
        print(label, type(e).__name__, e)

check("pow62", lambda: 2 ** 62)
check("powneg63", lambda: (-2) ** 63)
check("powodd", lambda: (-1) ** 9223372036854775807)
check("poweven", lambda: (-1) ** 9223372036854775806)
check("pow0", lambda: 0 ** 0)
check("mulbig", lambda: 3037000499 * 3037000499)
check("mulmix", lambda: 123456789 * 987654321)
check("submax", lambda: 9223372036854775807 - 1)
check("submin", lambda: -9223372036854775807 - 1)
check("absmin1", lambda: abs(-9223372036854775807))
check("lshift62", lambda: 1 << 62)
check("lshiftneg1", lambda: -1 << 63)
check("rshiftbig", lambda: 1 >> 100)
check("rshiftnegbig", lambda: -1 >> 200)
check("shift10e18", lambda: 10 ** 18)
try:
    print(1 << -1)
except ValueError as e:
    print(e)
try:
    print(2 >> -1)
except ValueError as e:
    print(e)
check("booladd", lambda: True + True)
check("boolmul", lambda: True * 5)
check("boolshift", lambda: True << 5)
check("intstrmax", lambda: int("9223372036854775807"))
check("intstrmin", lambda: int("-9223372036854775808"))
check("intbase", lambda: int("7fffffffffffffff", 16))
check("intpos", lambda: int(9.2e18))
check("intneg", lambda: int(-9.2e18))
try:
    print(int(float("inf")))
except OverflowError as e:
    print(e)
try:
    print(int(float("nan")))
except ValueError as e:
    print(e)
check("modneg1", lambda: -9223372036854775808 % -1)
check("divmodmin", lambda: divmod(-9223372036854775807, -1))
try:
    print(divmod(7, 0))
except ZeroDivisionError as e:
    print(e)
print("done")
