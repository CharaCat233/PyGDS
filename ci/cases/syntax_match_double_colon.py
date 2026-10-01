# 职责: case 1:: 双冒号触发解析期错误
# 比对: same_error

def f(x):
    match x:
        case 1::
            pass
