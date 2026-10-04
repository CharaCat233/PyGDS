# 职责: 任意精度 int 运算矩阵与快慢路径混合 (P0-13)
# 比对: same_output

# 字面量升级: 2**63 与 10**19 恰在 int64 边界两侧
print(2 ** 63)
print(10 ** 19)
print(2 ** 64)
print(-2 ** 63)
print(9223372036854775807 + 1)
print(-9223372036854775808 - 1)

# 快慢路径混合: 大数与 int64 混算, 结果落回 int64 时缩回
big = 2 ** 64
print(big - 2 ** 64)
print(big + (-2 ** 64))
print((2 ** 63) * 2)
print((2 ** 64) // (2 ** 32))
print((10 ** 30) % 7)
print((10 ** 30 + 5) % 10)

# 增强赋值与累乘
acc = 1
for i in range(1, 21):
    acc *= i
print(acc)
print(acc // 2432902008176640000)
acc -= 2432902008176640000
print(acc == 0)

# bool 与大数共享算术路径
print(True + 2 ** 64)
print(2 ** 64 * False)
print(-True * (10 ** 30))

# 与 float 混合: 精确比较 (10**30 的 double 展开比 10**30 大)
print(10 ** 30 == 1e30)
print(10 ** 30 > 1e30)
print(10 ** 30 + 0.5)
print(2 ** 53 + 1 == 9007199254740992.0)
print(2 ** 53 == 9007199254740992.0)

# divmod 与取模的符号语义 (CPython: 余数符号随除数)
print(divmod(10 ** 30, -7))
print(divmod(-(10 ** 30), 7))
print(divmod(-(10 ** 30), -7))
print((10 ** 30) // (-7), (10 ** 30) % (-7))

# 混合快慢路径的幂与巨指数
print(pow(2, 10 ** 30, 7))
print(pow(10 ** 30, 2, 97))
print(2 ** 100)
print(3 ** 50)

# 真除: 大数转 double, 巨值报 OverflowError
print(10 ** 30 / 3)
try:
    print(10 ** 400 / 3)
except OverflowError as e:
    print("OE:", e)
try:
    print(10 ** 400 + 0.5)
except OverflowError as e:
    print("OE2:", e)

# 深层表达式递归叠加 (P2-52 交叉敏感区)
print(1 + (2 ** 64 - 2 ** 64) + (2 ** 64 // 2 ** 63))
print("done")
