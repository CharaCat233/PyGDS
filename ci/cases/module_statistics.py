# 职责: mean/median/stdev 等统计量
# 比对: same_output

# statistics 模块测试

import statistics

# mean 平均值
print(statistics.mean([1, 2, 3, 4]))  # 2.5
print(statistics.mean([1, 1, 1]))  # 1.0
print(statistics.mean([5]))  # 5.0

# median 中位数
print(statistics.median([3, 1, 2]))  # 2 (奇数个取中间)
print(statistics.median([1, 2, 3, 4]))  # 2.5 (偶数个取平均)
print(statistics.median([7]))  # 7.0

# mode 众数
print(statistics.mode([1, 2, 2, 3]))  # 2
print(statistics.mode(["a", "b", "b"]))  # b
print(statistics.mode([1]))  # 1

# stdev 样本标准差 (n-1)
print(round(statistics.stdev([1, 2, 3, 4]), 6))  # 1.290994
print(round(statistics.stdev([1, 2, 3]), 6))  # 1.0

# pstdev 总体标准差 (n)
print(round(statistics.pstdev([1, 2, 3, 4]), 6))  # 1.118034
print(round(statistics.pstdev([1, 2, 3]), 6))  # 0.816497

# variance 样本方差
print(round(statistics.variance([1, 2, 3, 4]), 6))  # 1.666667
print(round(statistics.variance([1, 2, 3]), 6))  # 1.0

# pvariance 总体方差
print(round(statistics.pvariance([1, 2, 3, 4]), 6))  # 1.25
print(round(statistics.pvariance([1, 2, 3]), 6))  # 0.666667

# 错误路径: 数据点不足
try:
    statistics.mean([])
except statistics.StatisticsError as e:
    print("SE1:", e)
try:
    statistics.stdev([1])
except statistics.StatisticsError as e:
    print("SE2:", e)


# statistics 数值管线精确化 (大数回绕 + 浮点精确求和)
print(statistics.variance([10**20, 10**20 + 2]))
print(statistics.mean([10**20, 10**20 + 2]))
print(statistics.pvariance([10**20, 10**20 + 2]))
print(statistics.mean([0.1] * 10))
print(statistics.mean([1, 2, 3]))
print(statistics.mean([1, 2]))
print(statistics.variance([1, 2, 3]))
print(statistics.variance([1, 2]))
print(statistics.pvariance([1, 2, 3]))
print(statistics.stdev([1, 2, 3]))
print(statistics.pstdev([1, 2, 3]))
print(statistics.mean([10**20]))
print(statistics.variance([10**20, 10**20]))
print(statistics.mean([2**64, 2**64 + 2]))

# quantiles 位置参数校验 / inclusive / 越界保护
import statistics

data5 = [1, 2, 3, 4, 5]
try:
    statistics.quantiles(data5, 10)
except TypeError as e:
    print("q-pos:", str(e))
print("q-n1:", statistics.quantiles(data5, n=1))
try:
    statistics.quantiles(data5, n=0)
except Exception as e:
    print("q-n0:", type(e).__name__, str(e))
try:
    statistics.quantiles(data5, n=2.5)
except Exception as e:
    print("q-nf:", type(e).__name__, str(e))
print("q-incl:", statistics.quantiles(data5, method="inclusive"))
print("q-excl:", statistics.quantiles(data5))
try:
    statistics.quantiles(data5, method="foo")
except Exception as e:
    print("q-m:", type(e).__name__, str(e))
print("q-big:", statistics.quantiles(list(range(1, 11)), n=7))

# fmean / geometric_mean / harmonic_mean
print("fmean:", statistics.fmean([1, 2, 3, 4]))
print("gmean:", statistics.geometric_mean([2, 8]))
print("hmean:", statistics.harmonic_mean([1, 2, 4]))
try:
    statistics.fmean([])
except Exception as e:
    print("f-err:", type(e).__name__, str(e))
try:
    statistics.geometric_mean([-1, 2])
except Exception as e:
    print("g-err:", type(e).__name__, str(e))
try:
    statistics.harmonic_mean([-1, 2])
except Exception as e:
    print("h-err:", type(e).__name__, str(e))
print("hzero:", statistics.harmonic_mean([0, 2]))

# NormalDist 方法族: mean/stdev 为属性, pdf/cdf/inv_cdf/samples/from_samples 方法
nd = statistics.NormalDist(mu=3, sigma=2)
print("nd-mean:", nd.mean)
print("nd-stdev:", nd.stdev)
print("nd-pdf:", round(nd.pdf(3), 10))
print("nd-cdf:", round(nd.cdf(5), 6))
print("nd-cdf-inf:", nd.cdf(float("inf")))
print("nd-inv:", nd.inv_cdf(0.975))
print("nd-inv-half:", nd.inv_cdf(0.5))
try:
    nd.inv_cdf(1.5)
except Exception as e:
    print("nd-inv-err:", type(e).__name__, str(e))
try:
    nd.inv_cdf(0.0)
except Exception as e:
    print("nd-inv-zero:", type(e).__name__, str(e))
print("nd-samples:", statistics.NormalDist(0, 1).samples(3, seed=42))
nd2 = statistics.NormalDist.from_samples([2.4, 3.1, 3.6])
print("nd-from:", nd2.mean, round(nd2.stdev, 10))
try:
    statistics.NormalDist.from_samples([1.0])
except Exception as e:
    print("nd-from-1:", type(e).__name__, str(e))
print("nd-stdev-0:", statistics.NormalDist(1, 0).stdev)
try:
    statistics.NormalDist(1, 0).pdf(1)
except Exception as e:
    print("nd-pdf-s0:", type(e).__name__, str(e))
try:
    statistics.NormalDist(1, 0).cdf(1)
except Exception as e:
    print("nd-cdf-s0:", type(e).__name__, str(e))
print("nd-zscore:", nd.zscore(5))
try:
    statistics.NormalDist(1, 0).zscore(1)
except Exception as e:
    print("nd-zs0:", type(e).__name__, str(e))

# _mu/_sigma 赋值的数值归一 (int/bool/float 转 float 承载; 非 int/float/bool
# 原样保留与非数值静默可赋的赋值面差异登记为已知问题, 用例不覆盖)
nd3 = statistics.NormalDist(3, 2)
nd3._mu = 5.5
print("nd-assign-float:", (nd3._mu, nd3.mean))

# samples 的 seed 支持集校验 (None/int/float/str/bytes/bytearray)
try:
    statistics.NormalDist(0, 1).samples(2, seed=[1])
except TypeError as e:
    print("s-seed-list:", str(e).splitlines()[0])
print("s-seed-str:", len(statistics.NormalDist(0, 1).samples(2, seed="x")))
print("s-seed-float:", len(statistics.NormalDist(0, 1).samples(2, seed=1.5)))

# fmean 的 weights (CPython: num = sumprod(data, weights), den = fsum(weights))
print("fmean-w:", statistics.fmean([1, 2], weights=[1, 3]))
print("fmean-w2:", round(statistics.fmean([2, 5], weights=[2, 1]), 10))
try:
    statistics.fmean([1, 2], weights=[1])
except Exception as e:
    print("fmean-w-len:", type(e).__name__, str(e))
try:
    statistics.fmean([1, 2], weights=[0, 0])
except Exception as e:
    print("fmean-w-zero:", type(e).__name__, str(e))
print("fmean-w-big:", statistics.fmean([10**20, 1], weights=[1, 1]))

# median_grouped (CPython 公式: x 取中位元素, 二分定位等值区间)
print("mg:", statistics.median_grouped([1, 2, 3, 4]))
print("mg2:", statistics.median_grouped([1, 2, 3, 4], interval=2))
print("mg-odd:", statistics.median_grouped([2, 3, 4]))
print("mg-odd2:", statistics.median_grouped([2, 3, 4], interval=5))
print("mg-dup:", statistics.median_grouped([2, 3, 3, 4]))

# 大数样本经精确转 double (int64 快路径的 value 恒为 0)
print("fmean-big:", statistics.fmean([10**20, 1]))
print("harm-big:", statistics.harmonic_mean([10**20, 10**20]))
print("quant-big:", statistics.quantiles([10**20, 10**20 + 2, 10**20 + 4], n=2))
print("geo-big:", statistics.geometric_mean([10**20, 10**21]))

# NormalDist 构造与 samples 的实参校验群 (clinic 文案)
try:
    statistics.NormalDist(1, 2, 3)
except TypeError as e:
    print("nd-extra-pos:", str(e))
try:
    statistics.NormalDist(1, mu=2)
except TypeError as e:
    print("nd-mu-dup:", str(e))
try:
    statistics.NormalDist("x")
except ValueError as e:
    print("nd-str-mu:", str(e))
try:
    statistics.NormalDist.from_samples([1, 2], [3])
except TypeError as e:
    print("fs-extra:", str(e))
try:
    statistics.NormalDist(0, 1).samples()
except TypeError as e:
    print("smp-non:", str(e))
try:
    statistics.NormalDist(0, 1).samples(2.5)
except TypeError as e:
    print("smp-float:", str(e))
try:
    statistics.NormalDist(0, 1).samples(10**30)
except OverflowError as e:
    print("smp-big:", str(e))

# NormalDist 大数实参 (经精确转 double, 超 float 范围报 OverflowError)
nd4 = statistics.NormalDist(3, 2)
print("pdf-big:", nd4.pdf(10**100))
print("cdf-big:", nd4.cdf(10**100))

# NormalDist 运算符与相等 (CPython 3.12: mu 合并, sigma 平方和平方根)
n1 = statistics.NormalDist(0, 1)
n2 = statistics.NormalDist(1, 2)
print("nd-add:", repr(n1 + n2))
print("nd-sub:", repr(n2 - n1))
print("nd-eq:", statistics.NormalDist(0, 1) == statistics.NormalDist(0, 1))
print("nd-eq-other:", statistics.NormalDist(0, 1) == 5)

# NormalDist 非数值文案 (运算层/比较层)
try:
    nd4.pdf("x")
except TypeError as e:
    print("pdf-str:", str(e))
try:
    nd4.inv_cdf("x")
except TypeError as e:
    print("inv-str:", str(e))

# statistics 文案群 (空样本措辞与混合类型的异常类)
try:
    statistics.median([])
except statistics.StatisticsError as e:
    print("med-empty:", str(e))
try:
    statistics.mode([])
except statistics.StatisticsError as e:
    print("mode-empty:", str(e))
try:
    statistics.variance([1])
except statistics.StatisticsError as e:
    print("var-one:", str(e))
try:
    statistics.variance([1, "a"])
except TypeError as e:
    print("var-mixed:", str(e))

# LinearRegression 的 namedtuple 方法面与 dir 枚举
lr = statistics.linear_regression([1, 2, 3], [2, 4, 6])
print("lr-dir:", [n for n in dir(lr) if not n.startswith("_")])
print("lr-count:", lr.count(2.0))
