# 职责: async generator 体内带值 return 触发解析错误 (CPython 同文案)
# 比对: same_error

async def agen():
    yield 1
    return 5

