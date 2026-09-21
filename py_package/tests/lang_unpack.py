# 调用处 *args / **kwargs 解包测试

def add(a, b, c=0):
    return a + b + c

# *list 解包为位置参数
print(add(*[1, 2]))            # 3
print(add(*[1, 2, 3]))         # 6

# 混合: 位置参数 + * 解包
print(add(1, *[2]))            # 3

# **dict 解包为关键字参数
print(add(1, **{"b": 2, "c": 3}))   # 6

# 混合: * 与 ** 同时使用
print(add(*[1], **{"b": 2}))   # 3

# 通过变量解包
args = [10, 20]
print(add(*args))              # 30
kw = {"b": 5}
print(add(1, **kw))            # 6

# * 解包字符串 → 逐字符
def show(a, b, c):
    return (a, b, c)
print(show(*"xyz"))            # ('x', 'y', 'z')

# * 解包元组
tup = (1, 2, 3)
print(add(*tup))               # 6

# 与内置函数配合
print(max(*[3, 1, 4, 1, 5]))  # 5
print(min(*[3, 1, 4]))         # 1
print(divmod(*[10, 3]))        # (3, 1)

# print 的 * 解包
print(*[1, 2, 3], sep="-")     # 1-2-3

print("done")
