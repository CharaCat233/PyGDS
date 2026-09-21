# import / from-import 语句测试

# import 基础
import math
print(math.sqrt(16))        # 4.0
print(math.floor(3.7))      # 3
print(math.ceil(2.1))       # 3
print(math.fabs(-3.5))      # 3.5
print(math.pow(2, 3))       # 8.0
print(round(math.sqrt(2), 6))  # 1.414214

# import 别名
import math as m
print(m.floor(9.9))         # 9

# from-import 单个与别名
from math import floor, ceil as c
print(floor(1.9))           # 1
print(c(1.1))               # 2

# from math import *
from math import *
print(gcd(12, 18))          # 6
print(factorial(5))         # 120
print(isqrt(25))            # 5

# 导入不存在的模块 → ImportError
try:
    import nonexistent_module
except ImportError:
    print("caught import error")

# from-import 不存在的名字 → ImportError
try:
    from math import not_a_function
except ImportError:
    print("caught from error")

print("done")
