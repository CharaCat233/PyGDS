# 职责: 字典推导式内 yield 触发解析期错误
# 比对: same_error


def f():
    return {i: (yield i) for i in range(3)}
