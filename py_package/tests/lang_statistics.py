# statistics 模块测试

import statistics

# mean 平均值
print(statistics.mean([1, 2, 3, 4]))        # 2.5
print(statistics.mean([1, 1, 1]))           # 1.0
print(statistics.mean([5]))                 # 5.0

# median 中位数
print(statistics.median([3, 1, 2]))         # 2 (奇数个取中间)
print(statistics.median([1, 2, 3, 4]))      # 2.5 (偶数个取平均)
print(statistics.median([7]))               # 7.0

# mode 众数
print(statistics.mode([1, 2, 2, 3]))        # 2
print(statistics.mode(["a", "b", "b"]))     # b
print(statistics.mode([1]))                 # 1

# stdev 样本标准差 (n-1)
print(round(statistics.stdev([1, 2, 3, 4]), 6))      # 1.290994
print(round(statistics.stdev([1, 2, 3]), 6))         # 1.0

# pstdev 总体标准差 (n)
print(round(statistics.pstdev([1, 2, 3, 4]), 6))     # 1.118034
print(round(statistics.pstdev([1, 2, 3]), 6))        # 0.816497

# variance 样本方差
print(round(statistics.variance([1, 2, 3, 4]), 6))   # 1.666667
print(round(statistics.variance([1, 2, 3]), 6))      # 1.0

# pvariance 总体方差
print(round(statistics.pvariance([1, 2, 3, 4]), 6))  # 1.25
print(round(statistics.pvariance([1, 2, 3]), 6))     # 0.666667

print("done")
