# 职责: {**_} 通配 rest 触发解析期错误
# 比对: same_error

def f(x):
    match x:
        case {"a": v, **_}:
            pass
