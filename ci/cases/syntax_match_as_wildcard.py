# 职责: 模式 as 绑定通配符 _ 触发解析错误
# 比对: same_error

def f(x):
    match x:
        case 1 as _:
            pass
