# 职责: 大数快速路径一致性回归安全网
# 比对: same_output

# 确认项固化为 CI 用例: 大数四则/取模/移位/进制/divmod/round 及
# 作字典键的 in/取键/相等分桶、负数与混合符号、int/str 转换上限, 双端全同

# 大数作字典键: in / 取键 / 相等分桶
d = {10 ** 40: "big", 10 ** 400: "huge"}
print(10 ** 40 in d, 10 ** 41 in d, 10 ** 400 in d, 10 ** 399 in d)
print(d[10 ** 40], d[10 ** 400])
d2 = {10 ** 40: 1, 10 ** 41: 2, 10 ** 40: 3}
print(d2.get(10 ** 40), len(d2))
# 相等分桶: 10**40 与 (10**20)**2 相等且同桶
d3 = {10 ** 40: "a"}
print(d3.get((10 ** 20) ** 2))
print(10 ** 40 == (10 ** 20) ** 2, hash(10 ** 40) == hash((10 ** 20) ** 2))

# 10**40 与 10**400 量级四则 / 取模 / 移位 / 位运算
a, b = 10 ** 40, 10 ** 400
print(a + b, b - a, a * b, b // a, b % a, b % 7, a % 1000000007)
print(a << 10, b >> 100, a | b, a & b, a ^ b, ~a & b)
# 负数与混合符号
print(-a - b, b + (-a), -a * b, b // -a, b % -a, -b % a, (-a) // 3, (-b) % 9)
print((-a) ** 2, (-b) ** 3)
print(a > b, b > a, a < b, -a < -b, a == a, a != b)
# divmod 混合符号
print(divmod(b, a), divmod(-b, a), divmod(b, 7), divmod(a, -7), divmod(-b, -7))
# 取模符号
print(b % 7, b % -7, -b % 7, -b % -7)
# 进制 (radix) 与往返
print(hex(a), hex(b), oct(a), oct(b), bin(a), bin(b))
print(hex(-a), oct(-b), bin(-a))
print(int(hex(a), 16) == a, int(oct(b), 8) == b, int(bin(a), 2) == a)
# round 大数 (整数量级, 不触发浮点)
print(round(a), round(b), round(-a), round(a, 0), round(b, -2))
# int/str 转换
print(int(str(a)) == a, int(str(b)) == b, str(int(str(a))) == str(a))
print(int("9" * 50) == 10 ** 50 - 1)
print(a + 1, a - 1)
