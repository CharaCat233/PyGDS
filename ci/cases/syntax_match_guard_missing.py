# 职责: if 守卫缺表达式触发解析期错误
# 比对: same_error

def f(x):
    match x:
        case 1 if:
            pass
