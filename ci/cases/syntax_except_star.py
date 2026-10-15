# 职责: except* 块内 return 触发编译期 SyntaxError
# 比对: same_error


def f():
    try:
        pass
    except* ValueError:
        return 1
    return 0
