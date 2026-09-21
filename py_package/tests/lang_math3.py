# math / statistics 补全测试: remainder / cbrt / quantiles

import math
import statistics

# math.remainder: IEEE 754 余数, 商取最近偶数
print(math.remainder(7, 3))         # 1.0
print(math.remainder(-7, 3))        # -1.0
print(math.remainder(7, -3))        # 1.0
print(math.remainder(5, 2))         # 1.0
print(math.remainder(6, 2))         # 0.0
print(math.remainder(9, 3))         # 0.0
print(math.remainder(0.5, 1))       # 0.5
print(math.remainder(1.5, 1))       # -0.5 (商取偶)
print(math.remainder(2.5, 1))       # 0.5
print(math.remainder(-2.5, 1))      # -0.5
print(math.remainder(10, 3))        # 1.0

# math.cbrt: 立方根
print(math.cbrt(8))                 # 2.0
print(math.cbrt(27))                # 3.0
print(math.cbrt(-8))                # -2.0
print(math.cbrt(0))                 # 0.0
print(round(math.cbrt(2), 6))       # 1.259921
print(round(math.cbrt(-2), 6))      # -1.259921
print(round(math.cbrt(100), 6))     # 4.641589

# statistics.quantiles: 分位数 (exclusive 方法)
print(statistics.quantiles([1, 2, 3, 4]))                   # [1.25, 2.5, 3.75]
print(statistics.quantiles([0, 10, 20, 30]))                # [2.5, 15.0, 27.5]
print(statistics.quantiles([1, 2, 3, 4, 5]))                # [1.5, 3.0, 4.5]
print(statistics.quantiles([1, 2, 3, 4], n=2))              # [2.5]
print(statistics.quantiles([1, 2, 3, 4, 5, 6, 7, 8], n=4))  # [2.25, 4.5, 6.75]
print(statistics.quantiles([2, 4], n=2))                    # [3.0]
print(statistics.quantiles([5, 1, 3], n=2))                 # [3.0] (内部排序)

# quantiles 十分位
print(statistics.quantiles([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], n=10))

# StatisticsError 继承自 ValueError
print(issubclass(statistics.StatisticsError, ValueError))    # True

try:
    statistics.quantiles([1])
except statistics.StatisticsError:
    print("caught StatisticsError")     # caught StatisticsError

try:
    statistics.quantiles([])
except ValueError:
    print("caught as ValueError")       # caught as ValueError

print("done")
