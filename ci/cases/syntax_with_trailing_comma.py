# 职责: with trailing comma 触发解析期错误 (CPython 3.12 同文案)
# 比对: same_error

with x as a,:
    pass
