# 生成器抛异常时的求值传播测试 (与 CPython 行为一致)

# 调用表达式抛异常时不得把半成品值交给外层求值
def bad_iter():
    yield 1
    raise ValueError("mid")


try:
    print("LIST:", list(bad_iter()))
except ValueError as e:
    print("caught:", e)

try:
    print("TUPLE:", tuple(bad_iter()))
except ValueError as e:
    print("caught:", e)

# 类构造抛异常时同理
class C:
    def __init__(self):
        raise ValueError("init")


try:
    print("C:", C())
except ValueError as e:
    print("caught:", e)


# 已经正确的消费函数不应回归
def bad_iter2():
    yield 1
    raise ValueError("mid2")


try:
    print("SUM:", sum(bad_iter2()))
except ValueError as e:
    print("caught:", e)

try:
    print("SORTED:", sorted(bad_iter2()))
except ValueError as e:
    print("caught:", e)

# 不放在 print 里也应正确传播
try:
    list(bad_iter2())
except ValueError as e:
    print("caught:", e)

print("done")
