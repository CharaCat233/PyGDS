# 职责: __future__ 导入顶部位置与空操作语义
# 比对: same_output

# from __future__ import 为编译器指令, PyGDS 按语法空操作处理 (P1-61)
# 注意: 全部 __future__ 导入须位于文件头部 (CPython 位置规则)
from __future__ import annotations
from __future__ import print_function, generator_stop
from __future__ import (
    annotations,
    division,
    nested_scopes,
)

print("after future imports")


def late(a, b):
    return a + b


print(late(1, 2))

class K:
    flag = "ok"


print(K.flag)
