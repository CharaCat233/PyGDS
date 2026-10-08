# 职责: 用户类魔法方法返回类型校验 (__len__/__bool__/__init__/__repr__/__str__ 非法返回报 TypeError/ValueError, I2-63)
# 比对: same_output

# 协议非法返回值按 CPython 报错: __len__ 负数/非整数/大数, __bool__ 非 bool,
# __init__ 非 None, __repr__/__str__ 非字符串; 合法路径不受影响

def t(label, fn):
    try:
        print(label + ":", fn())
    except Exception as e:
        print(label, type(e).__name__, ":", e)


# === __len__ 返回非法值 ===
class LN:
    def __len__(self):
        return -1


t("len-neg", lambda: len(LN()))


class LS:
    def __len__(self):
        return "x"


t("len-str", lambda: len(LS()))


class LBig:
    def __len__(self):
        return 2 ** 200


t("len-big", lambda: len(LBig()))


class LBool:
    def __len__(self):
        return True


t("len-bool", lambda: len(LBool()))


# === __bool__ 返回非 bool ===
class BN:
    def __bool__(self):
        return 5


t("bool", lambda: bool(BN()))
t("bool-if", lambda: ("T" if BN() else "F"))
t("bool-not", lambda: not BN())
t("bool-and", lambda: BN() and "x")
t("bool-or", lambda: BN() or "x")
t("bool-ternary", lambda: "a" if BN() else "b")


def while_test():
    w = BN()
    while w:
        break
    return "loop"


t("bool-while", while_test)
t("bool-any", lambda: any([BN()]))


# === __init__ 返回非 None ===
class IN:
    def __init__(self):
        return 5


t("init", lambda: IN())


# === __repr__ / __str__ 返回非字符串 ===
class RN:
    def __repr__(self):
        return 5


t("repr", lambda: repr(RN()))


class SN:
    def __str__(self):
        return 5


t("str", lambda: str(SN()))
t("str-print", lambda: print(SN()))
t("str-fmt", lambda: "{}".format(SN()))


class Ronly:
    def __repr__(self):
        return 5


t("str-via-repr", lambda: str(Ronly()))


# === 合法路径不受影响 ===
class OK:
    def __bool__(self):
        return False

    def __len__(self):
        return 3

    def __repr__(self):
        return "ok-repr"

    def __str__(self):
        return "ok-str"


t("ok-bool", lambda: bool(OK()))
t("ok-len", lambda: len(OK()))
t("ok-repr", lambda: repr(OK()))
t("ok-str", lambda: str(OK()))
