# 职责: 列表推导式内裸 yield 触发解析期错误
# 比对: same_error


def f():
    return [yield i for i in range(3)]
