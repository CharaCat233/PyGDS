# 职责: 序列模式重复绑定同名触发解析错误
# 比对: same_error

def f(x):
    match x:
        case [a, a]:
            pass
