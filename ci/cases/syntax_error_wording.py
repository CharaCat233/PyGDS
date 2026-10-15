# 职责: 解析错误统一为 SyntaxError 类: 字面量赋值 / 裸 else / 不完整表达式 / 非法 del 目标等
# 比对: same_output


def t(label, fn):
    try:
        fn()
        print(label + ": OK")
    except SyntaxError:
        print(label + ": SYNTAX")


t("assign_literal", lambda: compile("1 = x", "<t>", "exec"))
t("else_alone", lambda: compile("else:\n    pass", "<t>", "exec"))
t("incomplete_expr", lambda: compile("x = 1 +", "<t>", "exec"))
t("del_no_target", lambda: compile("def f():\n    del", "<t>", "exec"))
t("bad_lambda", lambda: compile("f = lambda x=:", "<t>", "exec"))
t("bad_star_call", lambda: compile("def f():\n    pass\nf(*,)", "<t>", "exec"))
t(
    "unexpected_else",
    lambda: compile("x = 1\ny = 2\ndef g():\n    pass\nelse:\n    pass", "<t>", "exec"),
)
