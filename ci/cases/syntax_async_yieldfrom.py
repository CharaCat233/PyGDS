# 职责: async 函数体内 yield from 触发解析错误 (CPython 同文案)
# 比对: same_error

async def agen():
    yield from x

