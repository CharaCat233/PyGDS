# 职责: 捕获模式致后续 case 不可达报错
# 比对: same_error

def f(x):
    match x:
        case y:
            return 1
        case 2:
            return 2
