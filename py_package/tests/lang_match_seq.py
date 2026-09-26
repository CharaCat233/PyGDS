# match 序列模式: 固定长度, 星号, 无括号序列, 嵌套, 排除规则

# 固定长度
match [1, 2, 3]:
    case [a, b, c]:
        print(a, b, c)
    case _:
        print("no")

# 长度不符不匹配
match [1, 2, 3]:
    case [a, b]:
        print("two")
    case _:
        print("len-mismatch")

# 元组主题
match (4, 5):
    case (a, b):
        print("tuple", a, b)

# 星号捕获剩余
match [1, 2, 3, 4]:
    case [1, *rest]:
        print("star", rest)
    case _:
        print("no")

# 星号在中间
match [1, 2, 3, 4]:
    case [a, *mid, d]:
        print("mid", a, mid, d)

# 星号可为空
match [1]:
    case [a, *rest]:
        print("empty-rest", a, rest)

# 星号通配
match [1, 2, 3]:
    case [a, *_]:
        print("star-wild", a)

# 最少长度不满足
match [1]:
    case [a, b, *rest]:
        print("no")
    case _:
        print("too-short")

# 无括号序列 (open sequence)
def f_open(x):
    match x:
        case a, b:
            return (a, b)
        case _:
            return "n"
print(f_open([7, 8]), f_open((7, 8)), f_open([7, 8, 9]))

# 无括号序列带星号
def f_open_star(x):
    match x:
        case a, *rest:
            return (a, rest)
        case _:
            return "n"
print(f_open_star([1, 2, 3]), f_open_star([1]))

# 单元素尾逗号构成序列
match [9]:
    case [v, ]:
        print("trailing", v)

# 字面量无括号序列
match [1, 2]:
    case 1, 2:
        print("lit-open")

# 嵌套序列
def f_nest(x):
    match x:
        case [1, [a, b], c]:
            return (a, b, c)
        case _:
            return "n"
print(f_nest([1, [2, 3], 4]), f_nest([1, 2, 3]))

# 嵌套带星号
match [1, [2, 3, 4], 5]:
    case [1, [b, *inner], e]:
        print("nest-star", b, inner, e)

# 字符串与 bytes 不参与序列匹配
def f_seq(x):
    match x:
        case [a, b]:
            return "seq"
        case _:
            return "n"
print(f_seq("ab"), f_seq(b'AB'), f_seq([1, 2]), f_seq((1, 2)))

# 空序列
match []:
    case []:
        print("empty-list")

match ():
    case ():
        print("empty-tuple")

# 序列内字面量与捕获混合
match ["k", 3]:
    case ["k", v]:
        print("prefix", v)

# 组模式: 单元素圆括号等价于内部模式
match 1:
    case (1):
        print("group")

# 组模式包 or
match 2:
    case (1 | 2):
        print("group-or")

# 元组模式单元素尾逗号是序列
match [5]:
    case (v,):
        print("one-tuple")

print("done_seq")
