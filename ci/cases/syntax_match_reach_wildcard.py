# 职责: 通配模式致后续 case 不可达报错
# 比对: same_error

def f(x):
    match x:
        case _:
            return 1
        case 2:
            return 2
