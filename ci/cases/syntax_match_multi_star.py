# 职责: 序列模式出现多个星号触发解析错误
# 比对: same_error

def f(x):
    match x:
        case [a, *b, *c]:
            pass
