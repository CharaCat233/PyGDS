# 职责: 模式方括号未闭合触发解析期错误
# 比对: same_error

def f(x):
    match x:
        case [a, b:
            pass
