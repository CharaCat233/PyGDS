# 职责: **rest 与其余键混用触发解析错误
# 比对: same_error

def f(x):
    match x:
        case {**r, "a": v}:
            pass
