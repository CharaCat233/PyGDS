# 职责: str.format 手动/自动字段编号混用报 ValueError (I2-64)
# 比对: same_output

# 手动编号 ({0}/{1}) 与自动编号 ({}) 在同一格式串混用时报 ValueError,
# 文案按切换方向区分 (CPython 同); 嵌套规格与关键字实参参与编号模式跟踪

def t(label, fn):
    try:
        print(label + ":", fn())
    except Exception as e:
        print(label, type(e).__name__, ":", e)


t("manual-then-auto", lambda: "{1}{}".format(1, 2))
t("auto-then-manual", lambda: "{}{1}".format(1, 2))
t("nested-mix", lambda: "{0:{}}".format("a", 5))
t("manual-ok", lambda: "{1}{0}".format("a", "b"))
t("auto-ok", lambda: "{}{}".format("a", "b"))
t("kw-ok", lambda: "{0}{k}".format("a", k="z"))
t("manual-only", lambda: "{0}{0}".format("x"))
t("auto-multi", lambda: "{}{}{}".format(1, 2, 3))
t("nested-auto", lambda: "{:{}}".format("a", 5))
