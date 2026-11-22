# 职责: 关键字专属参数默认值顺序 (有无默认混合) 与调用期默认值槽位
# 比对: same_output


def f(*, a=1, b):
    return a + b


print(f(b=2), f(a=10, b=2))


def g(x=1, *, y):
    return x + y


print(g(5, y=2), g(y=2))


def h(a, b=2, *, c=3, d):
    return a + b + c + d


print(h(1, d=4), h(1, 2, d=4))
print(h(a=1, d=4))


def k(a, b=2, *, c=3, d=4):
    return a + b + c + d


print(k(1), k(1, d=9))

try:
    compile("def bad_slash(a=1, /, b): pass", "<t>", "exec")
except SyntaxError as err:
    print("slash:", str(err))
try:
    exec("def bad_pos(a=1, b): pass")
except SyntaxError as err:
    print("pos:", str(err))
