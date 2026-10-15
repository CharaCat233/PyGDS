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
