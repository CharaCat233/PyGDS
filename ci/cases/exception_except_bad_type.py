# 职责: except 子句类型非法 (非 BaseException 子类) 报 TypeError (I2-65)
# 比对: same_output

# 匹配阶段的 except 类型表达式必须是可捕获异常类 (自身或元组成员为 BaseException
# 子类的类), 否则按 CPython 报 TypeError; 元组全部成员先整体校验; 首个子句命中后
# 后续子句不再校验; try 体未抛异常时非法子句不触发

def t(label, fn):
    try:
        print(label + ":", fn())
    except Exception as e:
        print(label, type(e).__name__, ":", e)


def f1():
    try:
        raise ValueError("x")
    except 5:
        return "caught"
    return "propagated"


t("except-int", f1)


def f2():
    try:
        raise ValueError("x")
    except (ValueError, 5):
        return "caught"
    return "propagated"


t("except-tuple", f2)


def f3():
    try:
        raise TypeError("t")
    except TypeError:
        return "caught-ok"
    except 5:
        return "never"


t("first-match-shortcircuit", f3)


def f4():
    try:
        raise ValueError("x")
    except TypeError:
        pass
    except 5:
        return "never"
    return "propagated"


t("bad-later", f4)


def f5():
    try:
        raise ValueError("x")
    except object:
        return "caught-object"
    return "propagated"


t("except-object", f5)


def f6():
    try:
        raise ValueError("x")
    except BaseException:
        return "caught-base"
    return "propagated"


t("except-base", f6)


def f7():
    try:
        return "no-raise"
    except 5:
        return "never"


t("no-raise", f7)


def f8():
    out = "n/a"
    try:
        raise ValueError("x")
    except* 5:
        out = "caught*"
    return out


t("exceptstar-int", f8)
