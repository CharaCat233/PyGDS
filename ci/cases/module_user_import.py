# 职责: 用户文件 import (I1-8): sys.path 解析与模块缓存 / 成员与别名绑定 / __name__ / 循环导入部分初始化文案 / 未命中 ImportError, 模块内类与函数定义
# 比对: same_error
# 锚定: CPython 3.12
import sys
sys.path.insert(0, "ci/cases/files")
import mymod
print(mymod.VALUE)
print(mymod.double(4))
print(mymod.Widget.tag)
from mymod import double as d2
print(d2(5))
import mymod as m2
print(m2 is mymod)
try:
    import nomod
except ImportError as e:
    print("imp", e)
print(mymod.__name__)


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


import m2a
print("cycle a sees", m2a.B)
