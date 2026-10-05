# 职责: 文档字符串豁免仅对首个字符串语句成立 (I2-41)
# 比对: same_error
# 锚定: CPython 3.12

# 首个字符串语句是文档字符串, 第二个不是, 其后的 future 导入报位置错误
"module docstring"
"another string"
from __future__ import annotations
