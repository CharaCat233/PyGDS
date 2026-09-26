# match 与挂起机制: sleep 出现在主题, 守卫, case 体, property, 生成器中
import time

# 主题表达式含 sleep
def slow_subject():
    time.sleep(0.01)
    return 5
match slow_subject():
    case 1:
        print("one")
    case 5:
        print("five")

# 守卫含 sleep
def slow_guard(v):
    time.sleep(0.01)
    return v > 3
match 4:
    case y if slow_guard(y):
        print("big", y)
    case y:
        print("small", y)

# 守卫含 sleep 且失败, 落到下一个 case
def slow_fail(v):
    time.sleep(0.01)
    return v > 100
match 4:
    case y if slow_fail(y):
        print("huge", y)
    case y:
        print("fallback", y)

# case 体含 sleep
match 2:
    case 2:
        time.sleep(0.01)
        print("body two")

# 循环内 match 且 case 体含 sleep
for v in [1, 2, 3]:
    match v:
        case 2:
            time.sleep(0.01)
            print("hit", v)
        case _:
            print("skip", v)

# 嵌套用户函数调用含 sleep
def inner(x):
    time.sleep(0.01)
    return x * 10
match 3:
    case 3:
        print("inner:", inner(4))

# property getter 含 sleep 参与类模式属性匹配
class Prop:
    __match_args__ = ("v",)
    def __init__(self, val):
        self._v = val
    @property
    def v(self):
        time.sleep(0.01)
        return self._v
match Prop(7):
    case Prop(v=7):
        print("prop 7")
match Prop(8):
    case Prop(9):
        print("no")
    case _:
        print("prop miss")

# 值模式点号访问 getter 含 sleep
class Box:
    def __init__(self):
        self._n = 5
    @property
    def n(self):
        time.sleep(0.01)
        return self._n
box = Box()
match 3:
    case box.n:
        print("valprop 3")
match 5:
    case box.n:
        print("valprop 5")

# 生成器与 match 组合
def gen():
    for i in [1, 2, 3]:
        time.sleep(0.01)
        yield i
for g in gen():
    match g:
        case 2:
            print("gen two")
        case _:
            print("gen", g)

# 生成器函数体内使用 match
def gen_match():
    for v in [[1, 2], (3,)]:
        time.sleep(0.01)
        match v:
            case [a, b]:
                yield ("list", a, b)
            case (c,):
                yield ("tuple", c)
print(list(gen_match()))

print("done_sleep")
