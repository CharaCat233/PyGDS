# 职责: round/pow/divmod 内置函数
# 比对: same_output


print(round(3.14159, 2))  # 3.14
print(round(3.5))  # 4
print(round(2.5))  # 2
print(round(3.14159, 0))  # 3.0

print(pow(2, 3))  # 8
print(pow(2, 3, 5))  # 3 (2**3 % 5)
print(pow(2, 0))  # 1

print(divmod(10, 3))  # (3, 1)
print(divmod(7, 2))  # (3, 1)
print(divmod(5, 5))  # (1, 0)

# 负指数: 返回 float / 模逆
print(pow(2, -1))  # 0.5
print(pow(2, -1, 5))  # 3
try:
    pow(2, -1, 4)
except ValueError as e:
    print("NIV:", e)

# pow 三参模式浮点/非数字实参校验
try:
    pow(2.0, 3, 5)
except TypeError as e:
    print("TE-pow-f1:", e)
try:
    pow(2, 3.0, 5)
except TypeError as e:
    print("TE-pow-f2:", e)
try:
    pow(2, 3, 5.0)
except TypeError as e:
    print("TE-pow-f3:", e)
try:
    pow("2", 3, 5)
except TypeError as e:
    print("TE-pow-s1:", e)
try:
    pow(2, "3", 5)
except TypeError as e:
    print("TE-pow-s2:", e)
try:
    pow(2, 3, "5")
except TypeError as e:
    print("TE-pow-s3:", e)
print(pow(True, 3, 5))
print(pow(2, True, 5))
print(pow(2, 3, True))
