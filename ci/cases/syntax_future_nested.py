# 职责: 嵌套于函数体内的 from __future__ 导入同样报位置错误 (I2-41)
# 比对: same_error
# 锚定: CPython 3.12


def f():
    from __future__ import annotations
    return 1


print(f())
