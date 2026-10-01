# 职责: round/pow/divmod 内置函数
# 比对: same_output


print(round(3.14159, 2))     # 3.14
print(round(3.5))            # 4
print(round(2.5))            # 2
print(round(3.14159, 0))     # 3.0

print(pow(2, 3))             # 8
print(pow(2, 3, 5))          # 3 (2**3 % 5)
print(pow(2, 0))             # 1

print(divmod(10, 3))         # (3, 1)
print(divmod(7, 2))          # (3, 1)
print(divmod(5, 5))          # (1, 0)

# 负指数: 返回 float / 模逆
print(pow(2, -1))            # 0.5
print(pow(2, -1, 5))         # 3
try:
    pow(2, -1, 4)
except ValueError as e:
    print("NIV:", e)

print("done")