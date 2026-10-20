# 职责: 导入语句别名、星号导入与 ImportError
# 比对: same_output

# import / from-import 语句测试

# import 基础
import math

print(math.sqrt(16))  # 4.0
print(math.floor(3.7))  # 3
print(math.ceil(2.1))  # 3
print(math.fabs(-3.5))  # 3.5
print(round(math.pow(2, 3), 6))  # 8.0
print(round(math.sqrt(2), 6))  # 1.414214

# import 别名
import math as m

print(m.floor(9.9))  # 9

# from-import 单个与别名
from math import floor, ceil as c

print(floor(1.9))  # 1
print(c(1.1))  # 2

# from math import *
from math import *

print(gcd(12, 18))  # 6
print(factorial(5))  # 120
print(isqrt(25))  # 5

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



# 简单 import 失败抛 ModuleNotFoundError (ImportError 子类, 带 .name)
try:
    exec("import no_such_mod_qq_b5")
except ModuleNotFoundError as e:
    print(type(e).__name__, e.name)
try:
    exec("from no_such_mod_qq_b5b import x")
except ModuleNotFoundError as e:
    print(type(e).__name__, e.name)
try:
    exec("from math import nonexistent_b5")
except ImportError as e:
    print("IE:", str(e))

# builtins 模块可导入 (成员面 = 内建名全集, sys.modules 可见, 模块带 __name__)
import builtins

print(type(builtins).__name__)
print(builtins.len([1, 2]))
print(builtins.abs(-3))
print(builtins.__name__)
print("builtins" in __import__("sys").modules)

from builtins import len as blen

print(blen("abc"))
print(builtins.print is print)

import math as _m2

print(_m2.__name__)
print(math.__name__)
