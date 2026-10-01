# 职责: 顶层 *a 星号模式触发解析期错误
# 比对: same_error

def f(x):
    match x:
        case *a:
            pass
