# 职责: 标准库模块成员面外扩 (math/operator/functools/collections/string/itertools/base64/random/statistics)
# 比对: same_output

import math
import operator
import functools
import collections
import string
import itertools
import base64
import random
import statistics


def t(label, fn):
    try:
        print(label, fn())
    except Exception as e:
        print(label, type(e).__name__, e)


# math: 双曲/误差函数/浮点分解/相对性判定/精确求和/特殊函数
t("m_close", lambda: math.isclose(1.0, 1.0))
t("m_close_kw", lambda: math.isclose(1.0, 1.001, rel_tol=0.01))
t("m_close_abs", lambda: math.isclose(1.0, 1.5, abs_tol=0.6))
t("m_close_zero", lambda: math.isclose(0.0, 0.0))
t("m_cosh", lambda: round(math.cosh(0.5), 6))
t("m_sinh", lambda: round(math.sinh(0.5), 6))
t("m_tanh", lambda: round(math.tanh(0.5), 6))
t("m_acosh", lambda: round(math.acosh(2.0), 6))
t("m_asinh", lambda: round(math.asinh(0.5), 6))
t("m_atanh", lambda: round(math.atanh(0.5), 6))
t("m_exp2", lambda: math.exp2(3))
t("m_erf0", lambda: round(math.erf(0.0), 6))
t("m_erf_neg", lambda: round(math.erf(-0.5), 6))
t("m_erfc0", lambda: round(math.erfc(0.0), 6))
t("m_frexp8", lambda: math.frexp(8.0))
t("m_frexp0", lambda: math.frexp(0.0))
t("m_ldexp", lambda: math.ldexp(0.5, 4))
t("m_modf", lambda: math.modf(3.25))
t("m_modf_neg", lambda: math.modf(-3.25))
t("m_fsum", lambda: math.fsum([0.1, 0.2, 0.3]))
t("m_sumprod_i", lambda: math.sumprod([1, 2], [3, 4]))
t("m_sumprod_f", lambda: round(math.sumprod([0.1, 0.2], [1, 2]), 6))
t("m_sumprod_big", lambda: math.sumprod([10 ** 40], [10 ** 40]))
t("m_sumprod_big2", lambda: math.sumprod([10 ** 40, 1], [10 ** 40, 2]))
t("m_sumprod_mix", lambda: math.sumprod([10 ** 40, 0.5], [1, 2]))
t("m_gamma", lambda: math.gamma(5.0))
t("m_gamma_half", lambda: round(math.gamma(0.5), 6))
t("m_gamma_over", lambda: math.gamma(200))
t("m_gamma_neg_big", lambda: math.gamma(-200.5))
t("m_gamma_inf", lambda: math.gamma(float("inf")))
t("m_lgamma", lambda: round(math.lgamma(5.0), 6))
t("m_lgamma_200", lambda: round(math.lgamma(200.0), 6))
t("m_lgamma_half", lambda: round(math.lgamma(0.5), 6))
t("m_lgamma_inf", lambda: math.lgamma(float("inf")))
t("m_acosh_dom", lambda: math.acosh(0.5))
t("m_atanh_dom", lambda: math.atanh(2.0))
t("m_ulp0", lambda: math.ulp(0.0) > 0)
t("m_gamma_dom", lambda: math.gamma(-1))
# operator: 原位族 + call/inv
t("o_iadd", lambda: operator.iadd(1, 2))
t("o_isub", lambda: operator.isub(5, 2))
t("o_imul", lambda: operator.imul(3, 4))
t("o_itruediv", lambda: operator.itruediv(7, 2))
t("o_ipow", lambda: operator.ipow(2, 10))
t("o_ilshift", lambda: operator.ilshift(1, 4))
t("o_irshift", lambda: operator.irshift(64, 3))
t("o_iand", lambda: operator.iand(6, 3))
t("o_ior", lambda: operator.ior(6, 3))
t("o_ixor", lambda: operator.ixor(6, 3))
t("o_iconcat", lambda: operator.iconcat("a", "b"))
t("o_call", lambda: operator.call(len, "ab"))
t("o_inv", lambda: operator.inv(5))
t("o_iadd_list", lambda: _op_list())


def _op_list():
    lst = [1, 2]
    r = operator.iadd(lst, [3])
    return r is lst and lst == [1, 2, 3]


# functools: cache / cached_property / total_ordering / update_wrapper / get_cache_token
t("f_cache_call", lambda: _ft_cache_probe())


def _ft_cache_probe():
    calls = []

    @functools.cache
    def fib(n):
        calls.append(1)
        return n if n < 2 else fib(n - 1) + fib(n - 2)

    v = fib(10)
    return v, len(calls)


t("f_total_ordering", lambda: _ft_to_probe())


def _ft_to_probe():
    @functools.total_ordering
    class P:
        def __init__(self, v):
            self.v = v

        def __eq__(self, other):
            return self.v == other.v

        def __lt__(self, other):
            return self.v < other.v

    a = P(1)
    b = P(2)
    return a < b, b > a, a <= b, b >= a, a == P(1), a != b


t("f_update_wrapper", lambda: _ft_uw_probe())


def _ft_uw_probe():
    def real():
        "real doc"
        return 1

    def wrapper():
        return 2

    functools.update_wrapper(wrapper, real)
    return wrapper.__name__, wrapper.__doc__


t("f_token", lambda: type(functools.get_cache_token()).__name__)
t("f_cached_prop", lambda: _ft_cp_probe())


def _ft_cp_probe():
    class Box:
        @functools.cached_property
        def v(self):
            return 42

    b = Box()
    return b.v, b.v


# collections: ChainMap / User 族
t("c_cm_get", lambda: collections.ChainMap({"a": 1}, {"b": 2})["a"])
t("c_cm_len", lambda: len(collections.ChainMap({"a": 1}, {"b": 2})))
t("c_cm_write", lambda: _cm_write())


def _cm_write():
    cm = collections.ChainMap({"a": 1})
    cm["b"] = 2
    return cm["a"] + cm["b"], "a" in cm, "b" in cm


t("c_cm_newchild", lambda: _cm_child())


def _cm_child():
    cm = collections.ChainMap({"a": 1}).new_child({"b": 2})
    return cm["a"], cm["b"], len(cm.parents)


t("c_userdict", lambda: dict(collections.UserDict({1: 2})))
t("c_ud_ops", lambda: _ud_ops())


def _ud_ops():
    ud = collections.UserDict()
    ud["x"] = 5
    return ud["x"], len(ud), "x" in ud, ud.get("y", 9)


t("c_userlist", lambda: _ul_ops())


def _ul_ops():
    ul = collections.UserList([1, 2])
    ul.append(3)
    ul.extend([4])
    return list(ul), len(ul), ul.pop(), list(ul)


t("c_userstring", lambda: str(collections.UserString("ab")).upper())
t("c_us_ops", lambda: _us_ops())


def _us_ops():
    us = collections.UserString("ab")
    return us + "c", len(us), us == "ab", us.upper()


# string: Template / Formatter
t("s_tpl", lambda: string.Template("$x + $y").substitute(x=1, y=2))
t("s_tpl_dollar", lambda: string.Template("$$").substitute())
t("s_tpl_safe", lambda: string.Template("$x $z").safe_substitute(x=1))
t("s_tpl_brace", lambda: string.Template("${x}!").substitute(x=1))
t("s_tpl_miss", lambda: string.Template("$nope").substitute())
t("s_fmt", lambda: string.Formatter().format("{0}-{1}", 5, "a"))
t("s_fmt_kw", lambda: string.Formatter().format("{v}", v=9))
# itertools: compress / combinations_with_replacement
t("i_compress", lambda: list(itertools.compress("ABC", [1, 0, 1])))
t("i_compress_all", lambda: list(itertools.compress("AB", [True, 1])))
t("i_cwr", lambda: list(itertools.combinations_with_replacement("AB", 2)))
t("i_cwr_r0", lambda: list(itertools.combinations_with_replacement("AB", 0)))
t("i_cwr_same", lambda: list(itertools.combinations_with_replacement([1, 2, 3], 2)))
# base64: Base32 与 Ascii85/Base85 家族
t("b32e", lambda: base64.b32encode(b"ab"))
t("b32d", lambda: base64.b32decode(b"MFRA===="))
t("b32he", lambda: base64.b32hexencode(b"ab"))
t("b32hd", lambda: base64.b32hexdecode(b"C5H0===="))
t("a85e", lambda: base64.a85encode(b"ab"))
t("a85d", lambda: base64.a85decode(b"@:B"))
t("a85e_adobe", lambda: base64.a85encode(b"ab", adobe=True))
t("a85d_adobe", lambda: base64.a85decode(b"<~@:B~>", adobe=True))
t("a85_zero", lambda: base64.a85encode(b"\x00\x00\x00\x00"))
t("b85e", lambda: base64.b85encode(b"ab"))
t("b85d", lambda: base64.b85decode(b"VPX"))
t("b16e", lambda: base64.b16encode(b"ab"))
t("b32_round", lambda: base64.b32decode(base64.b32encode(b"hello")))
# random: 分布族可调用性与 SystemRandom
t("r_dist", lambda: (callable(random.expovariate), callable(random.normalvariate), callable(random.gammavariate), callable(random.betavariate), callable(random.lognormvariate), callable(random.paretovariate), callable(random.weibullvariate), callable(random.vonmisesvariate)))
t("r_sysrng", lambda: type(random.SystemRandom).__name__)
t("r_sysrng_use", lambda: random.SystemRandom().random() >= 0)
t("r_gamma_dom", lambda: random.gammavariate(0, 1))
# statistics: median 族 / 双变量统计 / NormalDist
t("s_mlow", lambda: statistics.median_low([1, 2, 3, 4]))
t("s_mhigh", lambda: statistics.median_high([1, 2, 3, 4]))
t("s_mlow_odd", lambda: statistics.median_low([3, 1, 2]))
t("s_mgrouped", lambda: statistics.median_grouped([1, 2, 3]))
t("s_multimode", lambda: statistics.multimode([1, 1, 2]))
t("s_multimode_tie", lambda: sorted(statistics.multimode([1, 1, 2, 2])))
t("s_corr", lambda: statistics.correlation([1, 2, 3], [1, 2, 3]))
t("s_cov", lambda: statistics.covariance([1, 2, 3], [1, 2, 3]))
t("s_lr", lambda: _lr_probe())


def _lr_probe():
    lr = statistics.linear_regression([1, 2], [1, 2])
    return lr.slope, lr.intercept


t("s_nd", lambda: statistics.NormalDist(mu=1).__class__.__name__)
t("s_nd_sigma", lambda: statistics.NormalDist(0, -1))
t("s_corr_len", lambda: statistics.correlation([1], [1, 2]))
t("s_corr_const", lambda: statistics.correlation([1, 1], [1, 2]))
