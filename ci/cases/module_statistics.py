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
