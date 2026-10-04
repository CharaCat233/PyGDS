# duty: 整型常量表达式折叠与驻留 (CPython 优化器同门控, 同表达式共享对象)
# compare: same_output
# anchor: CPython 3.12

# CPython 优化器折叠 10 ** 30 (门控 bits(10)*30=120 <= 128), 两次出现共享同一常量对象
x = 10 ** 30
y = 10 ** 30
print("pow10-30:", x is y)

# 折叠值为精确大数 (不落浮点)
print("pow2-64-val:", 2 ** 64)
print("pow2-64+1:", 2 ** 64 + 1)
print("pow10-30*3:", 10 ** 30 * 3)
print("sh127-val:", 1 << 127)
print("add64-val:", (2**64) + (2**64))

# 折叠驻留的正向形态: 门控内 (bits(2)*64=128, bits(1)+127=128, 无门控加法)
a = 2 ** 64
b = 2 ** 64
print("pow2-64:", a is b)
c = 1 << 127
d = 1 << 127
print("sh127:", c is d)
m = (2**64) + (2**64)
n = (2**64) + (2**64)
print("add64:", m is n)

# 折叠门控的拒折形态 (CPython 优化器同规则): 运行期求值产生不同实例
e = 2 ** 65
f = 2 ** 65
print("pow2-65:", e is f)
g = 1 << 128
h = 1 << 128
print("sh128:", g is h)
i = 12345678901234567890 * 98765432109876543210
j = 12345678901234567890 * 98765432109876543210
print("mul-bigits:", i is j)
k = 10 ** 80
l = 10 ** 80
print("pow10-80:", k is l)

# 各运算折叠值矩阵 (含负数 floor 语义)
print("mul-big:", 123456789 * 987654321 * 123456789)
print("floordiv:", -7 // 2, 7 // -2, -7 // -2)
print("mod:", -7 % 2, 7 % -2, -7 % -2)
print("shift:", 1 << 100, (-1) >> 80)
print("bits:", 0xFF00FF | 0x0F0F0F, 0xFF00FF & 0x0F0F0F, 0xFF00FF ^ 0x0F0F0F)
print("neg-pow:", (-2) ** 61, (-2) ** 62)
print("zero-pow:", 0 ** 0, 0 ** 5)
print("chained:", 2 * 3 + 4 * 5, (2 + 3) * (4 + 5))
print("div-float:", 10 / 4, 7 / 2)
print("bool-no-fold:", True + 1)

# 求值遇错不折叠, 保留运行期报错 (CPython 优化器同规则)
try:
    print("div0:", 1 // 0)
except ZeroDivisionError as err:
    print("div0 ZeroDivisionError:", err)
try:
    print("mod0:", 1 % 0)
except ZeroDivisionError as err:
    print("mod0 ZeroDivisionError:", err)
try:
    print("negshift:", 1 << -2)
except ValueError as err:
    print("negshift ValueError:", err)
try:
    print("hugeshift:", 1 << (2 ** 70))
except OverflowError as err:
    print("hugeshift OverflowError:", err)

# 字符串 concat 折叠回归 (编译期身份, 与整型折叠共存)
s = "ab" + "cd"
print("concat-fold:", s is "abcd")
