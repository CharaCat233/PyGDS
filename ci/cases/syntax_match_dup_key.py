# 职责: 映射模式 1 与 1.0 判为重复键报错
# 比对: same_error

def f(x):
    match x:
        case {1: a, 1.0: b}:
            pass
