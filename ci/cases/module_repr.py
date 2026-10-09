# 职责: 模块 repr 形态 (内置 <module 'x' (built-in)>, I2-68)
# 比对: same_output

# 内置模块 repr 为 <module 'x' (built-in)>; 用户模块为 <module 'x' from 'path'>
# (本用例仅测 CPython 亦为内置的模块, 其余 PyGDS 内置而 CPython 为 .py 的模块
# 路径形态差异记录为 I2-68 残余; 用户模块路径形态由文件类用例覆盖)

import math
import time
import sys

print(repr(math))
print(repr(time))
print(repr(sys))
print(str(math))
