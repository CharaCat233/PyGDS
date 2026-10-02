# 职责: 增强赋值运算符求值
# 比对: same_output


x = 10
x += 5
x *= 2
x //= 3
print(x)  # 10

# 位运算增强赋值 (P1-68)
b1 = 12
b1 &= 10
print(b1)                    # 8
b2 = 5
b2 ^= 3
print(b2)                    # 6
b3 = 3
b3 <<= 2
print(b3)                    # 12
b4 = 16
b4 >>= 2
print(b4)                    # 4

# set 的原地对称差走同一链路 (P1-68)
s1 = {1, 2, 3}
s1 ^= {2}
print(sorted(s1))            # [1, 3]
