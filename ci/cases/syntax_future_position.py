# 职责: 文件中部 from __future__ 导入的 CPython 位置报错 (I2-41)
# 比对: same_error
# 锚定: CPython 3.12

# 非文档字符串语句先行后 future 导入报位置错误
x = 1
from __future__ import annotations

print(x)
