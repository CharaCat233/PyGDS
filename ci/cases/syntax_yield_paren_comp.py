# 职责: 括号 yield 作推导式元素触发解析错误
# 比对: same_error


def f():
    return [(yield i) for i in range(3)]
