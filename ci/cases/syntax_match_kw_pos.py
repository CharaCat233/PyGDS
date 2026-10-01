# 职责: 关键字模式后接位置模式触发解析错误
# 比对: same_error

def f(x):
    match x:
        case P(x=1, 2):
            pass
