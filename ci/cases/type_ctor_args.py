# 职责: 内建类型构造器参数个数 / 关键字 / base 校验文案 (I2-58)
# 比对: same_output
# 锚定: CPython 3.12


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


# int: 参数个数按位置 + 关键字合计, 上限 2 (CPython takes at most 文案)
t("int3", lambda: int("C", (), {}))
t("int3b", lambda: int(1, 10, 3))
t("int4", lambda: int("C", 10, 3, 4))
t("int_kw3", lambda: int("C", (), base=2))
t("int_dup", lambda: int("11", 2, base=2))

# int: base 关键字生效 (原先被静默忽略)
t("int_base_kw", lambda: int("11", base=2))
t("int_base_kw_hex", lambda: int("ff", base=16))
t("int_bogus_kw", lambda: int("11", bogus=2))
t("int_bogus_only", lambda: int(bogus=1))
t("int_base_only", lambda: int(base=2))

# int: base 须可索引化, 显式 float / str / tuple / None 均拒绝
t("base_float", lambda: int("11", 2.5))
t("base_str", lambda: int("11", "2"))
t("base_tuple", lambda: int("11", ()))
t("base_none", lambda: int("11", None))
t("base_kw_str", lambda: int("11", base="2"))

# int: base 合法域 0 或 2..36 (bool base 经索引化收敛)
t("base_bool", lambda: int("11", True))
t("base_big", lambda: int("11", 10 ** 30))

# str: 参数个数按位置 + 关键字合计, 上限 3 (CPython takes at most 文案)
t("str4", lambda: str(1, 2, 3, 4))

# float / bool / list / tuple: 不接受关键字参数 (原先被静默忽略)
t("float_kw", lambda: float(x=1))
t("bool_kw", lambda: bool(x=1))
t("list_kw", lambda: list(iterable=[1, 2]))
t("tuple_kw", lambda: tuple(iterable=(1, 2)))

# 对照组: 通用参数个数文案双端本已一致, 不受本批改动影响
t("dict3", lambda: dict("C", (), {}))
t("float3", lambda: float("C", (), {}))
t("bool3", lambda: bool("C", (), {}))
t("list3", lambda: list("C", (), {}))
t("tuple3", lambda: tuple("C", (), {}))

# 子类构造共享同一校验 (无用户 __init__ 覆写时)


class I(int):
    pass


class F(float):
    pass


class L(list):
    pass


class T(tuple):
    pass


t("sub_int3", lambda: I("C", (), {}))
t("sub_int_base_kw", lambda: I("11", base=2))
t("sub_int_kw_pos", lambda: I("11", 2, base=2))
t("sub_int_plain", lambda: I(5))
t("sub_f_kw", lambda: F(x=1))
t("sub_f_two", lambda: F(1.0, 2))
t("sub_l_kw", lambda: L(iterable=[1, 2]))
t("sub_l_two", lambda: L([1], 2))
t("sub_l_plain", lambda: L([1, 2]))
t("sub_t_kw", lambda: T(x=1))
t("sub_t_two", lambda: T((1,), 2))
t("sub_t_plain", lambda: T((1, 2)))
