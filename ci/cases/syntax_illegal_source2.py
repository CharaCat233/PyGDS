# 职责: 一批编译期约束缺失修复: 非法参数形态 / 非法 del 目标 / 空括号导入 /
# 比较后一元 not / yield from 元组 / else 体 break / 条件表达式裸 lambda
# 比对: same_output


def t(label, fn):
    try:
        fn()
        print(label + ": OK")
    except SyntaxError:
        print(label + ": SYNTAX")


t("def_star", lambda: compile("def f(*): pass", "<t>", "exec"))
t("def_slash", lambda: compile("def f(/): pass", "<t>", "exec"))
t("def_multi_slash", lambda: compile("def f(a, /, /, b): pass", "<t>", "exec"))
t("def_default_order", lambda: compile("def f(a=1, b): pass", "<t>", "exec"))
t("def_walrus_default_ok", lambda: compile("def f(x = (y := 5)): pass", "<t>", "exec"))
t("call_paren_kw", lambda: compile("f((x) = 1)", "<t>", "exec"))
t("del_call", lambda: compile("del f()", "<t>", "exec"))
t("del_binary", lambda: compile("a = 1\nb = 2\ndel a + b", "<t>", "exec"))
t("import_empty", lambda: compile("from math import ()", "<t>", "exec"))
t("comp_in_not", lambda: compile("a = 1\nb = 1\nx = a in not b", "<t>", "exec"))
t("yield_from_tuple", lambda: compile("def g():\n    yield from x, y", "<t>", "exec"))
t(
    "while_else_break",
    lambda: compile("while False:\n    pass\nelse:\n    break", "<t>", "exec"),
)
t(
    "try_else_break",
    lambda: compile(
        "try:\n    pass\nexcept:\n    pass\nelse:\n    break", "<t>", "exec"
    ),
)
t(
    "try_else_noexcept",
    lambda: compile("try:\n    pass\nelse:\n    pass", "<t>", "exec"),
)
t("if_lambda", lambda: compile("1 if lambda: 2 else 3", "<t>", "exec"))
# 合法形态不回归: 括号 lambda 条件 / yield from 单表达式 / del 正常目标
t("if_lambda_paren_ok", lambda: compile("1 if (lambda: 2) else 3", "<t>", "exec"))
t("yield_from_ok", lambda: compile("def g():\n    yield from [1, 2]", "<t>", "exec"))
