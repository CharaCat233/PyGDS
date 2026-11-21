# 职责: 模块 repr 形态 (内置 <module 'x' (built-in)>)
# 比对: same_output

# 内置模块 repr 为 <module 'x' (built-in)>, 用户模块为 <module 'x' from 'path'>
# (本用例仅测 CPython 亦为内置的模块, 其余 PyGDS 内置而 CPython 为 .py 的模块, 用户模块路径形态由文件类用例覆盖)
# math 在 Windows CPython 为内建, 在 Linux 为扩展模块 (路径随宿主安装位置变化), 位置段按 FILE_PATH 占位归一

import math
import time
import sys


def _norm(s):
    if " from '" in s:
        return s[: s.find(" from '")] + " from 'FILE_PATH'>"
    return s.replace("(built-in)", "from 'FILE_PATH'")


print(_norm(repr(math)))
print(repr(time))
print(repr(sys))
print(_norm(str(math)))
