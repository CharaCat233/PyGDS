# 元组下标: 字典的复合键写法 (v0.6.0-alpha.2)

# 基本元组键
d = {(1, 2): "a", (3,): "b", 5: "c"}
print(d[1, 2])
print(d[3,])
print(d[5])

# 元组键赋值 / 增强赋值 / 删除
d[1, 2] = "z"
print(d[1, 2])
d[1, 2] += "!"
print(d[1, 2])
del d[3,]
print(d[(1, 2)], d[5])

# 与元组变量等价
t = (1, 2)
print(d[t], d[(1, 2)], d[1, 2] == d[t])
print((1, 2) in d)

# 嵌套元组与混合元素
n = {((1, 2), 3): "deep"}
print(n[(1, 2), 3])
m = {("a", 1): "s", (2.5, True): "f"}
print(m["a", 1], m[2.5, True])

# 三元素与尾逗号
tri = {(1, 2, 3): "tri"}
print(tri[1, 2, 3])
print(tri[1, 2, 3,])

# 非字典容器的元组下标报错
s = "abc"
try:
    print(s[1, 2])
except TypeError:
    print("str-typeerr")
lst = [1, 2, 3]
try:
    print(lst[1, 2])
except TypeError:
    print("list-typeerr")

# 下标元组内的表达式
d2 = {(1 + 1, 2 * 3): "calc"}
print(d2[2, 6])
x = 1
print(d2[x + 1, x * 6])

# 复合键不与普通键冲突
mixed = {1: "int", (1,): "tup", "1": "str"}
print(mixed[1], mixed[1,], mixed["1"])

print("done_tuple_sub")
