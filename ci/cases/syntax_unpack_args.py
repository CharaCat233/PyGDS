# 职责: 调用处解包的错误路径（实参数量与键名不匹配）
# 比对: same_output

def add3(a, b, c):
    return a + b + c

# 正向: * 与 ** 混合解包按位置/键名对齐
print(add3(*[1], **{"b": 2, "c": 3}))

# * 解包数量超出形参 → TypeError
try:
    add3(*[1, 2, 3, 4])
except TypeError:
    print("too many")

# * 解包数量不足 → TypeError
try:
    add3(*[1])
except TypeError:
    print("too few")

# ** 解包出现形参之外的键 → TypeError
try:
    add3(1, 2, 3, **{"d": 4})
except TypeError:
    print("unexpected kw")

# 对非可迭代对象做 * 解包 → TypeError
try:
    add3(*5)
except TypeError:
    print("not iterable")
