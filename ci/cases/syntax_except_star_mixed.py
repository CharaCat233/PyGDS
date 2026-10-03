# 职责: except 与 except* 混用于同一 try 触发解析错误 (CPython 同文案)
# 比对: same_error

try:
    pass
except ValueError:
    pass
except* TypeError:
    pass

