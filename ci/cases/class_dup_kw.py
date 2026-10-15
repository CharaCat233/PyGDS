# 职责: 类头关键字参数重复的编译期 SyntaxError (CPython 同文案)
# 比对: same_error


class Dup(k=1, k=2):
    pass
