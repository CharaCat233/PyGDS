# 职责: from __future__ 导入的 _Feature 绑定与文档字符串位置豁免 (I2-41)
# 比对: same_output
# 锚定: CPython 3.12

"""module docstring"""

from __future__ import annotations
from __future__ import division as div, generator_stop
from __future__ import (
    nested_scopes,
    print_function,
)
from __future__ import barry_as_FLUFL

# _Feature 对象 repr: _Feature(可选版本, 强制版本, 编译器标志) 三元组形态
print(repr(annotations))
print(repr(div))
print(repr(nested_scopes))
print(repr(generator_stop))
print(repr(barry_as_FLUFL))

# 类型形态与属性访问
print(type(annotations).__name__)
print(div.compiler_flag)
print(div.optional)
print(div.mandatory)
print(annotations.mandatory)
print(div.optional == div.optional)

# as 别名绑定与多特性一次导入
print(repr(generator_stop))
print(nested_scopes.compiler_flag)
print(print_function.compiler_flag)
