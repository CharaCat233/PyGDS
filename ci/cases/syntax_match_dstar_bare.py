# 职责: {**} 缺捕获名触发解析期错误
# 比对: same_error

def f(x):
    match x:
        case {**}:
            pass
