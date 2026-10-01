# 职责: 模式后多余记号触发解析期错误
# 比对: same_error

def f(x):
    match x:
        case 1 1:
            pass
