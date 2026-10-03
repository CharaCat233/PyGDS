# 职责: never-awaited 警告 (未启动协程, CPython GC 时点 / PyGDS 收尾时点为既定差异)
# 比对: same_output

# CPython 侧经 warnings 捕获打印; PyGDS 无 warnings 模块, 协程在脚本收尾时
# 经 print 通道发出 RuntimeWarning: coroutine 'x' was never awaited
have_warnings = False
try:
    import warnings
    have_warnings = True
except ImportError:
    pass


async def lonely():
    return 1


async def second():
    return 2


if have_warnings:
    with warnings.catch_warnings(record=True) as w:
        warnings.simplefilter("always")
        lonely()
        second()
        for wi in w:
            print(wi.category.__name__ + ": " + str(wi.message))
else:
    lonely()
    second()
