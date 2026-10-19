# 职责: int/bool 数值协议与转换 dunder 直调、as_integer_ratio / is_integer
# 比对: same_output


def t(label, fn):
    try:
        print(label, fn())
    except Exception as e:
        print(label, type(e).__name__, e)


t("idx", lambda: (3).__index__())
t("int_", lambda: (3).__int__())
t("float_", lambda: (3).__float__())
t("hash_eq", lambda: (3).__hash__() == hash(3))
t("hash_neg", lambda: (-3).__hash__() == hash(-3))
t("floor", lambda: (3).__floor__())
t("ceil", lambda: (3).__ceil__())
t("trunc", lambda: (3).__trunc__())
t("abs_", lambda: (3).__abs__())
t("abs_neg", lambda: (-3).__abs__())
t("index_neg", lambda: (-3).__index__())
t("ratio", lambda: (3).as_integer_ratio())
t("ratio_neg", lambda: (-3).as_integer_ratio())
t("is_int", lambda: (3).is_integer())
t("idx_true", lambda: (True).__index__())
t("int_true", lambda: (True).__int__())
t("hash_true", lambda: (True).__hash__() == hash(True))
t("abs_true", lambda: (True).__abs__())
t("ratio_true", lambda: (True).as_integer_ratio())
t("is_int_true", lambda: (True).is_integer())
t("float_noidx", lambda: hasattr(3.5, "__index__"))
t("big_int_", lambda: (2 ** 70).__int__())
t("big_ratio", lambda: (2 ** 70).as_integer_ratio())
t("big_hash", lambda: (2 ** 70).__hash__() == hash(2 ** 70))
t("bool_idx0", lambda: (False).__index__())
t("int_add", lambda: (3).__add__(4))
t("int_neg", lambda: (3).__neg__())
