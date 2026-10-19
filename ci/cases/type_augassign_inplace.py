# 职责: 增强赋值对内建容器的原地变更别名语义
# 比对: same_output

# dict |= / set |= / bytearray += 此前新建对象重绑 (别名不可见)
# 改为原地 update / extend 并返回自身 (list += 已具原地语义)

# list += 原地 (别名可见)
a = [1]
b = a
a += [2]
print(b)
print(a is b)

# list += 非列表可迭代 (extend 语义)
a = [1]
a += (2, 3)
print(a)
a = [1]
a += range(2)
print(a)
a = [1]
a += "ab"
print(a)

# dict |= 原地
d1 = {"a": 1}
d2 = d1
d1 |= {"b": 2}
print(d2)
print(d1 is d2)
d1 |= {}
print(d2)

# set |= 原地
s1 = {1}
s2 = s1
s1 |= {2}
print(s2)
print(s1 is s2)
s1 |= {3, 4}
print(s2)

# bytearray += 原地
ba = bytearray(b"a")
bb = ba
ba += b"b"
print(bb)
print(ba is bb)
ba2 = bytearray(b"x")
ba2 += b"yz"
print(ba2)
ba3 = bytearray(b"y")
ba3 += b"z"
print(ba3)

# 返回自身: 原地方法返回对象本身
d3 = {}
d3 |= {"k": 1}
print(d3)
d3 |= {"k2": 2}
print(d3)
l1 = []
l1 += [1]
print(l1)

# 非原地类型保持新建 (int 等不可变)
x = 1
y = x
x += 1
print(y, x)

# set -= / &= / ^= 与 list *= 原地语义 (别名持有者可见变更)
s1 = {1, 2}
s2 = s1
s1 -= {1}
print(sorted(s2), s1 is s2)
s3 = {1, 2}
s4 = s3
s3 &= {2}
print(sorted(s4), s3 is s4)
s5 = {1, 2}
s6 = s5
s5 ^= {2, 3}
print(sorted(s6), s5 is s6)
a = [1]
b = a
a *= 2
print(b, a is b)
c = [1, 2]
d = c
c *= 0
print(d, c)
e = [1]
f = e
e *= -1
print(f, e)
g = [3]
h = g
g *= True
print(h, g)
# |= / += 原地回归 (既有面)
i1 = {1}
i2 = i1
i1 |= {2}
print(sorted(i2), i1 is i2)
j1 = [1]
j2 = j1
j1 += [2]
print(j2)

# 类型错误与大数计数
try:
    k = {1, 2}
    k -= [1]
except TypeError as err:
    print("TE-sub:", err)
try:
    m = {1, 2}
    m &= 1
except TypeError as err:
    print("TE-and:", err)
try:
    n1 = [1]
    n1 *= "x"
except TypeError as err:
    print("TE-mul:", err)
try:
    n2 = [1]
    n2 *= 10 ** 100
except OverflowError as err:
    print("OE-mul:", err)

# -= / ^= 仅接受 set 形操作数 (CPython __isub__/__ixor__ 门槛), &= 接受任意可迭代
try:
    p1 = {1, 2}
    p1 ^= [9]
except TypeError as err:
    print("TE-xor:", err)
d111 = {"a": 1, 2: "b"}
q1 = {1, 2, 3}
q1 &= d111.keys()
print(sorted(q1))

# |= 仅接受 set 形操作数 (CPython set.__ior__ 门槛), 列表实参报运算符 TypeError
try:
    t1 = {1}
    t1 |= [2]
except TypeError as err:
    print("TE-ior:", err)
r1 = {1, 2, 3}
r1 -= frozenset({1})
print(sorted(r1))
r2 = {1, 2, 3}
r2 &= frozenset({2})
print(sorted(r2))
r3 = {1, 2, 3}
r3 ^= frozenset({3})
print(sorted(r3))
