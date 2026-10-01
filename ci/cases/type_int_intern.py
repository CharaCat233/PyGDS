# 职责: 小整数 -5..256 驻留与 bool 单例
# 比对: same_output

# 小整数驻留: -5..256 等值整数共享同一实例

a = 5
b = 5
print(a is b)

n = 255
m = 250 + 5
print(n is m)

p = 256
q = 128 + 128
print(p is q)

t = -5
u = -2 - 3
print(t is u)

# 转换路径同样命中缓存
print(int("42") is (40 + 2))
five = 5
print(int(5) is five)
print(len("abcd") is 4)

# 迭代计数走缓存
c1 = 0
for i in range(3):
    c1 = i
two = 2
print(c1 is two)

# 范围外不驻留 (变量运算的运行期结果)
big1 = 300
big2 = 150
big3 = big2 + big2
print(big1 is big3)

# bool 单例不受影响
tt = True
one = 1
print(tt is one)
f1 = False
f2 = 0
print(f1 is f2)

print(id(a) == id(b))
