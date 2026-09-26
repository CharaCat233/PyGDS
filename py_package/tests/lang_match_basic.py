# match / case 基础: 字面量, 捕获, 通配, 守卫, 或模式, as, 软关键字

# 字面量分支
match 5:
    case 1:
        print("one")
    case 5:
        print("five")
    case _:
        print("other")

# 捕获永远匹配
match 42:
    case v:
        print("cap", v)

# 通配不绑定
match 7:
    case _:
        print("wild")

# 守卫
match 4:
    case y if y > 3:
        print("big", y)
    case y:
        print("small", y)

match 2:
    case y if y > 3:
        print("big", y)
    case y:
        print("small", y)

# 单例字面量身份语义
def f_true(x):
    match x:
        case True:
            return "T"
        case _:
            return "n"
print(f_true(1), f_true(True))

def f_none(x):
    match x:
        case None:
            return "N"
        case _:
            return "n"
print(f_none(None), f_none(0))

# 数字字面量相等语义 (1 == 1.0 == True)
def f_num(x):
    match x:
        case 1:
            return "one"
        case _:
            return "n"
print(f_num(1), f_num(1.0), f_num(True))

# 负数字面量
def f_neg(x):
    match x:
        case -3:
            return "neg"
        case _:
            return "n"
print(f_neg(-3), f_neg(3))

# 字符串字面量
match "hi":
    case "ho":
        print("ho")
    case "hi":
        print("hi")

# 或模式
for v in [1, 2, 3]:
    match v:
        case 1 | 3:
            print("hit", v)
        case _:
            print("miss", v)

# 或模式加 as
match 2:
    case (1 | 2) as z:
        print("oras", z)
    case _:
        print("no")

# as 捕获整个主题
match [1, 9]:
    case [1, y] as whole:
        print("as", y, whole)

# 主题表达式元组
def f_subj(a, b):
    match a, b:
        case (0, 0):
            return "oo"
        case (0, y):
            return ("y", y)
        case (x, 0):
            return ("x", x)
        case _:
            return "other"
print(f_subj(0, 0), f_subj(0, 4), f_subj(6, 0), f_subj(6, 4))

# 捕获之后的 case 不可达 (前一无守卫捕获), 语法错误在 err 用例覆盖;
# 带守卫的捕获不遮蔽后续
match 5:
    case y if y < 0:
        print("neg")
    case y:
        print("pos", y)

# 守卫失败后绑定保留
def f_keep(x):
    msg = ""
    match x:
        case y if x < 0:
            msg = "neg"
        case _:
            msg = "wild"
    return (msg, y)
print(f_keep(5))

# 软关键字: match / case 作普通标识符
match = 1
case = 2
print(match + case)

match = [1, 2]
match[0] = 9
print(match)

def match(x):
    return x * 2
print(match(21))

d = {"match": 1, "case": 2}
print(d["match"] + d["case"])

# 循环内 match
for v in [1, "a", None]:
    match v:
        case 1:
            print("int")
        case "a":
            print("str")
        case None:
            print("none")
        case _:
            print("other")

# 函数内 match 绑定局部变量
def f_scope(x):
    match x:
        case [p, q]:
            r = p + q
        case _:
            r = -1
    return r
print(f_scope([10, 20]), f_scope([1, 2, 3]))

print("done_basic")
