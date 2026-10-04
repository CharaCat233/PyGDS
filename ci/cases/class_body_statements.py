# 职责: 类体完整语句执行 (P0-25): 表达式副作用、if/for/while 流控、增强赋值、del、try/except/finally、import、注解、global、断言、match
# 比对: same_output

# 表达式副作用
class C1:
    print("hi")
    x = 1 + 1

print(C1.x)

# if / for / while 流控与绑定
flag = True


class C2:
    if flag:
        mode = "on"
    else:
        mode = "off"
    total = 0
    for i in range(4):
        total += i
    n = 10
    while n > 6:
        n -= 1

print(C2.mode, C2.total, C2.n, C2.i)

# 增强赋值与 del
class C3:
    v = 10
    v += 5
    w = v * 2
    del w
    z = 3

print(C3.v, C3.z)
try:
    print(C3.w)
except AttributeError:
    print("no w")

# try / except / finally
class C4:
    ok = False
    try:
        1 / 0
    except ZeroDivisionError as e:
        caught = type(e).__name__
        ok = True
    finally:
        fin = "done"

print(C4.ok, C4.caught, C4.fin)

# import 落入类字典
class C5:
    import math
    half = math.pi / 2

print(round(C5.half, 3), C5.math.floor(2.7))

# 注解求值并入 __annotations__
class C6:
    a: int = 5
    b: "str" = "x"

print(C6.__annotations__["a"].__name__, C6.a, C6.b)

# global 声明写入模块全局
g_acc = 0


class C7:
    global g_acc
    g_acc = 42

print(g_acc, hasattr(C7, "g_acc"))

# 断言语句执行
class C8:
    assert 1 + 1 == 2
    msg = "asserted"

print(C8.msg)
