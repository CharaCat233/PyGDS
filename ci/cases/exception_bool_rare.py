# 职责: __bool__ 非 bool 在稀路径的错误传播 (异常组 filter / 惰性谓词 / operator, I2-63)
# 比对: same_output

# __bool__ 返回非 bool 时: 异常组 filter 类型校验 (非可调用报 TypeError)、
# 可调用 filter 返回坏真值对象报 TypeError、filter/takewhile/dropwhile 惰性谓词、
# operator.truth/not_、any/all 均按 CPython 传播

import itertools
import operator


class Bad:
    def __bool__(self):
        return 5


def t(label, fn):
    try:
        print(label + ":", fn())
    except Exception as e:
        print(label, type(e).__name__, ":", e)


# 异常组 filter 类型校验 (非可调用 / 非类 / 非元组)
def grp_bad():
    g = ExceptionGroup("g", [ValueError("a")])
    return g.subgroup(Bad())


t("group-filter-bad", grp_bad)


def grp_split_bad():
    g = ExceptionGroup("g", [ValueError("a")])
    return g.split(Bad())


t("group-split-bad", grp_split_bad)


# 可调用 filter 返回坏真值对象 (__bool__ 非 bool)
def grp_callable():
    g = ExceptionGroup("g", [ValueError("a")])
    return g.subgroup(lambda x: Bad())


t("group-filter-callable-bad", grp_callable)


# 惰性迭代器谓词结果的真值
t("filter-lazy", lambda: list(filter(lambda x: Bad(), [1, 2])))
t("takewhile", lambda: list(itertools.takewhile(lambda x: Bad(), [1, 2])))
t("dropwhile", lambda: list(itertools.dropwhile(lambda x: Bad(), [1, 2])))

# operator.truth / not_
t("op-truth", lambda: operator.truth(Bad()))
t("op-not", lambda: operator.not_(Bad()))

# any / all
t("any", lambda: any([Bad()]))
t("all", lambda: all([Bad()]))

# 正常 filter (可调用返回正常 bool) 不受影响
t("ok-filter", lambda: list(filter(lambda x: x > 1, [1, 2, 3])))
t("ok-group", lambda: ExceptionGroup("g", [ValueError("a")]).subgroup(ValueError))
