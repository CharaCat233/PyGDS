# lambda 表达式支持测试

# 基本 lambda
f = lambda x: x * 2
print(f(21))               # 42

# 立即调用
print((lambda x: x + 1)(9))   # 10

# 默认参数
g = lambda a, b=10: a + b
print(g(5))                # 15
print(g(5, 100))           # 105

# 多参数
add = lambda a, b, c: a + b + c
print(add(1, 2, 3))        # 6

# 无参数
h = lambda: "no args"
print(h())

# 作为 sort/sorted 的 key
lst = [3, 1, 2]
lst.sort(key=lambda x: -x)
print(lst)                 # [3, 2, 1]
print(sorted([1, 2, 3], key=lambda x: -x))  # [3, 2, 1]

# 与 map/filter 配合
print(list(map(lambda x: x ** 2, [1, 2, 3])))      # [1, 4, 9]
print(list(filter(lambda x: x % 2 == 0, [1, 2, 3, 4])))  # [2, 4]

# 作为参数传递
def apply(fn, v):
    return fn(v)
print(apply(lambda x: x * 10, 5))    # 50

# 捕获外部变量 (闭包)
base = 100
add_base = lambda x: x + base
print(add_base(1))         # 101

# 条件表达式
sign = lambda n: "pos" if n > 0 else ("neg" if n < 0 else "zero")
print(sign(5))             # pos
print(sign(-5))            # neg
print(sign(0))             # zero

# 存储在容器中
funcs = {"double": lambda x: x * 2, "triple": lambda x: x * 3}
print(funcs["double"](4))  # 8
print(funcs["triple"](4))  # 12

print("done")
