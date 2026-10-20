# 职责: 未识别转义 (\8 \9 \p \q 等) 按 CPython 发 SyntaxWarning (每字面量首处), 值仍保留字面量, bytes 同逻辑
# 比对: same_output

# CPython 侧经 warnings 捕获打印; PyGDS 无 warnings 模块, 解析期经 print 通道发出
# compile 与 exec 都会各解析一次, 捕获块须同时罩住两次解析使双端告警条数一致
have_warnings = False
try:
    import warnings

    have_warnings = True
except ImportError:
    pass


def esc_case(src):
    ns = {}
    if have_warnings:
        with warnings.catch_warnings(record=True) as w:
            warnings.simplefilter("always")
            compile(src, "<t>", "exec")
            exec(src, ns)
            for wi in w:
                print(wi.category.__name__ + ": " + str(wi.message))
    else:
        compile(src, "<t>", "exec")
        exec(src, ns)
    print(repr(ns.get("x")))


# str 未识别转义: 告警一次, 值保留反斜杠与该字符
esc_case("x = '\\8'")
esc_case("x = '\\9'")
esc_case("x = '\\p'")
# 同一字面量多处未识别转义: 仅首处告警
esc_case("x = '\\8\\9'")
esc_case("x = '\\p\\q'")
# 相邻两个字面量: 各自告警
esc_case("x = '\\8' '\\9'")
# 未识别转义与超范围八进制混排: 仅首处告警
esc_case("x = '\\8\\400'")
# 三引号字面量 (文档串) 同样告警
esc_case("def f():\n    '\\q'\n    return 1\nx = f()")
# bytes 未识别转义: 同 str (含 \u 形态)
esc_case("x = b'\\8'")
esc_case("x = b'\\9'")
esc_case("x = b'\\u00e9'")
# bytes 超范围八进制: 同 str 文案, 值仍按单字节截断
esc_case("x = b'\\400'")
# 已支持转义不告警
esc_case("x = '\\n\\t\\x41\\101'")
esc_case("x = b'\\n\\t\\x41\\101'")
