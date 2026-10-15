# 职责: nonlocal 无绑定与模块级声明: 编译期即报 SyntaxError, 消息按 CPython 对齐
# 比对: same_output


def t(label, src):
    try:
        compile(src, "<t>", "exec")
        print(label + ": OK")
    except SyntaxError:
        print(label + ": SYNTAX")


t("unbound", "def f():\n    nonlocal x\n    x = 1")
t("module_level", "nonlocal y")
