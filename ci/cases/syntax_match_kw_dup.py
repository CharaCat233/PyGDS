# 职责: 类模式关键字参数重复触发解析错误
# 比对: same_error

def f(x):
    match x:
        case P(x=1, x=2):
            pass
