# 职责: 或模式各分支绑定名不一致报错
# 比对: same_error

def f(x):
    match x:
        case 1 | y:
            pass
