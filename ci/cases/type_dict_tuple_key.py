# 职责: 字典元组复合键 d[1, 2] 写法
# 比对: same_output

# 元组下标: 字典的复合键写法

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
print(
    tri[
        1,
        2,
        3,
    ]
)

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



# 元组键编码此前用 | 直拼, 含 | 的元素构造碰撞静默覆盖
# 改为长度前缀拼接 (("a", 1) 与 ("a|1",) 不再同键)
def t_label(fn):
    try:
        print(fn())
    except Exception as e:
        print(type(e).__name__, ":", e)


d = {}
d[("a", 1)] = 1
d[("a|1",)] = 2
print(len(d))
print(d[("a", 1)], d[("a|1",)])

d2 = {}
d2[("a,b",)] = 1
d2[("a", "b")] = 2
print(len(d2))
print(d2[("a,b",)], d2[("a", "b")])

d3 = {}
d3[("a", "b")] = 1
d3[("ab",)] = 2
print(len(d3))

# 嵌套元组与含分隔符元素
d4 = {}
d4[(("x|y",), 2)] = 1
d4[("x", ("y", 2))] = 2
print(len(d4))

# 等值元组仍命中同键 (覆盖语义)
d5 = {}
d5[("a", 1)] = 1
d5[("a", 1)] = 9
print(len(d5), d5[("a", 1)])

# frozenset 键同站点 (此前也用 | 直拼)
d6 = {}
d6[frozenset({"a|1"})] = 1
d6[frozenset({"a", "1"})] = 2
print(len(d6))
print(d6[frozenset({"a|1"})], d6[frozenset({"a", "1"})])

# set 的元组元素同站点
s = {("a,b",), ("a", "b")}
print(len(s))
s2 = {("a", 1), ("a|1",)}
print(len(s2))
