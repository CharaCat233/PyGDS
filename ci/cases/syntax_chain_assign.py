# 职责: 链式下标/属性赋值解析
# 比对: same_output

# 字典下标链式赋值 (dict 插入序与 CPython 一致, 从左到右)
d = {}
d["a"] = d["b"] = 5
print(d)

# 列表下标链式赋值
l = [0, 0]
l[0] = l[1] = 7
print(l)


# 属性链式赋值
class O:
    pass


o = O()
o.x = o.y = 9
print(o.x, o.y)


# 下标表达式 (函数调用) 链式
def k(s):
    return s


d2 = {}
d2[k("a")] = d2[k("b")] = 3
print(d2)

# 首个目标为下标 + 变量链
d3 = {}
d3["a"] = x = 5
print(d3, x)

# 变量 + 下标混合链 (值只求值一次, 从左到右)
v = 0
arr = [0, 0]
v = arr[0] = arr[1] = 2
print(v, arr)

# 三目标下标链
l3 = [0, 0, 0]
l3[0] = l3[1] = l3[2] = 9
print(l3)


# 属性三目标链
class P:
    pass


p = P()
p.a = p.b = p.c = 3
print(p.a, p.b, p.c)

# 简单变量链 (既有形态)
a = b = 5
print(a, b)
x = y = z = 1
print(x, y, z)

# 下标链与既有解包形态共存
q, w = 1, 2
q, w = w, q
print(q, w)
