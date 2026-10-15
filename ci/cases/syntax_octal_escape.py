# 职责: 超范围八进制转义发 SyntaxWarning: \400-\777 值仍解码但告警, -W error 时升 SyntaxError
# 比对: same_output

# CPython 侧经 warnings 捕获打印; PyGDS 无 warnings 模块, 解析期经 print 通道发出
# SyntaxWarning: invalid octal escape sequence '\400' (值仍按 chr(0o400) 解码)
have_warnings = False
try:
    import warnings

    have_warnings = True
except ImportError:
    pass


def oct_case(src):
    if have_warnings:
        with warnings.catch_warnings(record=True) as w:
            warnings.simplefilter("always")
            compile(src, "<t>", "exec")
            for wi in w:
                print(wi.category.__name__ + ": " + str(wi.message))
    else:
        compile(src, "<t>", "exec")


# 超范围: 3 位八进制值 > 0o377
oct_case("x = '\\400'")
oct_case("x = '\\777'")
# 合法: 值 <= 0o377, 无告警
oct_case("x = '\\377'")
# 合法: 前两位八进制 + 字面量尾随, 无告警
oct_case("x = '\\378'")
