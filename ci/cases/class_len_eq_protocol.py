# 职责: 用户 __len__ 返回 bool/__eq__ 返回整数的协议校验
# 比对: same_output

# __len__ 返回 False 此前按默认真值处理 (应为 0), __eq__ 返回 1
# 此前落回身份比较 (应按真值判定); __len__ 返回负数报 ValueError


def t(label, fn):
    try:
        print(label + ":", fn())
    except Exception as e:
        print(label, type(e).__name__, ":", e)


# === __len__ 返回 bool (bool 是 int 子类) ===
class LF:
    def __len__(self):
        return False


t("len-false-bool", lambda: bool(LF()))
t("len-false-len", lambda: len(LF()))


class LT:
    def __len__(self):
        return True


t("len-true-bool", lambda: bool(LT()))
t("len-true-len", lambda: len(LT()))


# === __len__ 返回负数报 ValueError (此前静默真) ===
class LNeg:
    def __len__(self):
        return -1


t("len-neg-bool", lambda: bool(LNeg()))
t("len-neg-len", lambda: len(LNeg()))


# === __len__ 返回大数/非整数 (与既有校验一致) ===
class LBig:
    def __len__(self):
        return 2**200


t("len-big-bool", lambda: bool(LBig()))


# === __eq__ 返回整数按真值判定 (此前落回身份比较恒 False) ===
class E1:
    def __eq__(self, o):
        return 1


t("eq-int1", lambda: E1() == E1())
t("eq-int1-in", lambda: E1() in [1])
t("eq-int1-count", lambda: [E1()].count(E1()))


class E0:
    def __eq__(self, o):
        return 0


t("eq-int0", lambda: E0() == E0())
t("eq-int0-in", lambda: E0() in [1])


# __eq__ 返回 float 按真值判定 (CPython: 结果直接参与真值)
class EF:
    def __eq__(self, o):
        return 1.5


t("eq-float", lambda: EF() == EF())


class EZ:
    def __eq__(self, o):
        return 0.0


t("eq-float0", lambda: EZ() == EZ())
