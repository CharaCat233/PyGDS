# 职责: 残余内建类型构造器 kwargs 与 deque maxlen 语义 (I2-59)
# 比对: same_output
# 锚定: CPython 3.12
from collections import deque


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


# set / frozenset: 关键字拒绝与个数校验 (kwargs 按槽名 set()/frozenset() 报)
t("set_kw", lambda: set([1], bogus=2))
t("set_kw_only", lambda: set(x=1))
t("frozenset_kw", lambda: frozenset([1], bogus=2))
t("set2", lambda: set(1, 2))
t("set_seq2", lambda: set([1], 2))
t("frozenset2", lambda: frozenset(1, 2))
t("set_int", lambda: set(1))
t("frozenset_int", lambda: frozenset(1))
t("set_none", lambda: set(None))
t("set_empty", lambda: set())
t("set_str", lambda: sorted(set("aab")))

# slice: 关键字拒绝与无参文案
t("slice_kw", lambda: slice(start=1))
t("slice_kw2", lambda: slice(1, stop=2))
t("slice_kw4", lambda: slice(1, 2, 3, x=4))
t("slice0", lambda: slice())
t("slice1", lambda: (slice(1).start, slice(1).stop, slice(1).step))
t("slice3", lambda: (slice(1, 2, 3).start, slice(1, 2, 3).stop, slice(1, 2, 3).step))
t("slice4", lambda: slice(1, 2, 3, 4))

# deque: maxlen 关键字与第二位置参数生效
t("deque_kw", lambda: list(deque([1, 2], maxlen=1)))
t("deque_kw_maxlen", lambda: deque([1, 2], maxlen=1).maxlen)
t("deque_pos2", lambda: list(deque([1, 2], 1)))
t("deque_default", lambda: deque([1]).maxlen)
t("deque_none", lambda: deque([1], maxlen=None).maxlen)
t("deque_zero", lambda: (list(deque(maxlen=0)), deque(maxlen=0).maxlen))
t("deque_zero_fill", lambda: list(deque([1, 2], maxlen=0)))

# deque: 超限收敛 (append / extend / appendleft / extendleft)
d6 = deque([1, 2, 3], maxlen=2)
d6.append(4)
t("deque_append_over", lambda: list(d6))
d7 = deque([1, 2, 3], maxlen=2)
d7.extend([4, 5])
t("deque_extend_over", lambda: list(d7))
d8 = deque([1], maxlen=2)
d8.appendleft(0)
t("deque_appendleft", lambda: list(d8))
d8b = deque([1, 2], maxlen=2)
d8b.appendleft(0)
t("deque_appendleft_over", lambda: list(d8b))
d12 = deque([1, 2], maxlen=3)
d12.extendleft([7, 8])
t("deque_extendleft_over", lambda: list(d12))

# deque: maxlen 类型与取值校验
t("deque_neg", lambda: deque([1], maxlen=-1))
t("deque_float", lambda: deque([1], maxlen=1.5))
t("deque_str", lambda: deque([1], maxlen="2"))
t("deque_bool", lambda: (list(deque([1, 2], maxlen=True)), deque([1, 2], maxlen=True).maxlen))
t("deque_big", lambda: deque([1], maxlen=2 ** 63))
t("deque_huge", lambda: deque([1], maxlen=2 ** 64))

# deque: 构造参数合计计数与未知关键字
t("deque_int_iter", lambda: deque(1))
t("deque3", lambda: deque([1], 2, 3))
t("deque_bogus", lambda: deque([1], bogus=2))
t("deque_kw_and_pos", lambda: deque([1], 2, maxlen=3))
t("deque_none_arg", lambda: deque(None))

# deque: 拼接 / 重复 / 增强赋值保留左侧 maxlen
t("deque_add", lambda: (list(deque([1], maxlen=3) + deque([2, 3])), (deque([1], maxlen=3) + deque([2, 3])).maxlen))
d10 = deque([1], maxlen=2)
d10 += deque([5, 6])
t("deque_iadd", lambda: (list(d10), d10.maxlen))
t("deque_iadd_str", lambda: (lambda d: (d.__iadd__("ab"), list(d)))(deque([0])))
t("deque_mul", lambda: list(deque([1]) * 2))
t("deque_mul_maxlen", lambda: (deque([1, 2], maxlen=3) * 2).maxlen)
t("deque_mul_big", lambda: deque([1]) * 2 ** 63)
t("deque_mul_neg", lambda: list(deque([1]) * -1))
t("deque_mul_str", lambda: deque([1]) * "a")
t("str_mul_d", lambda: "a" * deque([1]))
t("d_plus_list", lambda: deque([1]) + [2])
t("list_plus_d", lambda: [1] + deque([2]))

# deque: repr / 属性 / 方法面
t("deque_repr", lambda: repr(deque([1, 2], maxlen=3)))
t("deque_repr_empty", lambda: repr(deque(maxlen=3)))
t("deque_repr_plain", lambda: repr(deque([1])))
d11 = deque([1], maxlen=2)
t("deque_maxlen_set", lambda: (setattr(d11, "maxlen", 5), d11.maxlen))
t("deque_hash", lambda: hash(deque([1])))
t("deque_type", lambda: type(deque([1])))
t("deque_type_name", lambda: type(deque([1])).__name__)
t("deque_lt", lambda: deque([1]) < deque([2]))
t("deque_gt", lambda: deque([3]) > deque([2]))
t("deque_le", lambda: deque([1, 2]) <= deque([2]))
t("deque_ge", lambda: deque([2]) >= deque([2]))
t("deque_lt_list", lambda: deque([1]) < [1])
t("deque_eq_list", lambda: deque([1]) == [1])
t("deque_insert_full", lambda: (lambda d: d.insert(1, 9))(deque([1, 2], maxlen=2)))
t("deque_insert_mid", lambda: (lambda d: (d.insert(1, 9), list(d)))(deque([1, 2, 3])))
t("deque_insert_neg", lambda: (lambda d: (d.insert(-1, 9), list(d)))(deque([1, 2, 3])))
t("deque_insert_clamp", lambda: (lambda d: (d.insert(100, 9), list(d)))(deque([1, 2, 3])))
t("deque_insert_negclamp", lambda: (lambda d: (d.insert(-100, 9), list(d)))(deque([1, 2, 3])))
t("deque_insert_float", lambda: (lambda d: d.insert(0.5, 9))(deque([1])))
t("deque_insert_big", lambda: (lambda d: d.insert(2 ** 63, 9))(deque([1])))
t("deque_insert_1arg", lambda: (lambda d: d.insert(1))(deque([1])))
t("deque_copy_maxlen", lambda: deque([1], maxlen=3).copy().maxlen)
t("deque_iter_init", lambda: list(deque(iter([1, 2]))))
t("deque_gen_init", lambda: list(deque(x for x in [1, 2])))
t("deque_dict_init", lambda: list(deque({"a": 1})))
t("extend_iter", lambda: (lambda d: (d.extend(iter([7, 8])), list(d)))(deque([0])))

# None 初值: 可迭代构造器统一报错 (原先静默返回空容器)
t("list_none", lambda: list(None))
t("tuple_none", lambda: tuple(None))
t("dict_none", lambda: dict(None))
t("bytearray_none", lambda: bytearray(None))


class S9(set):
    pass


t("S9_type", lambda: type(S9([1])))
t("S9_isinstance", lambda: isinstance(S9([1]), set))
