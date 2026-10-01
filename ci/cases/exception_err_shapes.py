# 职责: format/切片/幂/setattr 错误形态合集
# 比对: same_output

try:
    "{missing}".format(x=1)
except KeyError as e:
    print("KF:", e, e.args)
try:
    "{} {}".format(1)
except IndexError as e:
    print("IF:", e)
print("%d %x" % (True, True))
print("%.1f|%s" % (2.25, format(2.25, ".1f")))
try:
    "abc"[::0]
except ValueError as e:
    print("STEP:", e)
try:
    0 ** -1
except ZeroDivisionError as e:
    print("ZD:", e)
try:
    0.0 ** -2
except ZeroDivisionError as e:
    print("ZD2:", e)
try:
    setattr(1, "x", 2)
except AttributeError as e:
    print("AE:", e)
print("abc".startswith(("x", "a")), "abc".endswith(("c", "y")))
try:
    [1, 2].index(9)
except ValueError as e:
    print("VI:", e)
print([0] * -1, "ab" * -1, (1,) * -2)
print(0 < True, sorted([True, False]), min([True, False]), max([2, True]))
