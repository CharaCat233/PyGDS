# duty: from m import * 遵守模块 __all__ 导出面
# 比对: same_output
import sys

sys.path.insert(0, ".")

# 沙箱自建模块: __all__ 限定导出面 (含下划线名, 未列名字不导出)
with open("mall_star.py", "w") as f:
    f.write("__all__ = ['a', '_hidden', 'b']\na = 1\n_hidden = 2\nb = 3\nc = 4\n")

from mall_star import *

print("a" in globals(), "b" in globals(), "c" in globals(), "_hidden" in globals())
print(a, b, _hidden)

# 无 __all__ 时按 CPython 只导入非下划线开头成员
with open("mall_star2.py", "w") as f:
    f.write("a = 1\n_b = 2\nc = 3\n")

from mall_star2 import *

print("a" in globals(), "c" in globals(), "_b" in globals())
print(a, c)

# __all__ 含缺失名: 报 AttributeError
with open("mall_star3.py", "w") as f:
    f.write("__all__ = ['a', 'missing_x']\na = 1\n")

try:
    from mall_star3 import *
except AttributeError as e:
    print("AE:", e)
