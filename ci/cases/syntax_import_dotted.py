# 职责: 点分 import 与相对导入的错误类别 (I2-71)
# 比对: same_output

# 点分 import (import a.b / from a.b import x) 在运行期报 ModuleNotFoundError
# (CPython 同), 不再于解析期报 Unexpected token '.'; 相对导入 (from . import x)
# 报 ImportError: attempted relative import with no known parent package;
# 正常导入不受影响

def t(label, fn):
    try:
        print(label + ":", fn())
    except Exception as e:
        print(label, type(e).__name__, ":", e)


def dotted_math():
    import math.floor
    return "ok"


t("import-math-floor", dotted_math)


def dotted_nonexist():
    import nonexist.sub
    return "ok"


t("import-nonexist-sub", dotted_nonexist)


def from_dotted():
    from math.floor import x
    return "ok"


t("from-math-floor", from_dotted)


def rel1():
    from . import x
    return "ok"


t("from-rel-dot", rel1)


def rel2():
    from ..mod import x
    return "ok"


t("from-rel-dotdot", rel2)


def rel3():
    from . import sqrt
    return "ok"


t("from-rel-dot-named", rel3)


# 正常导入不受影响
def ok_import():
    import math
    from math import sqrt
    return (math.pi > 3, sqrt(9))


t("ok-import", ok_import)
