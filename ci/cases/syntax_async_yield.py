# 职责: async def 体内 yield 为 PyGDS 既定边界 (CPython 3.12 为合法 async generator, 单边差异不判定)
# 比对: same_error
# 跳过: 既定边界——PyGDS 拒绝 async def 内 yield 并报 SyntaxError, CPython 3.12 接受为
# async generator (3.6+), 单边报错无法双端判定; 边界随 P1-9 方案 C 记录于 README 与 usage

async def agen():
    yield 1
