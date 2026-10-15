# 职责: 大整数在异常消息/KeyError 文案的 repr 渲染
# 比对: same_output

# 大整数经 _py_repr 渲染此前恒为 "0" (大数 value 恒 0)
# 异常 args 与 KeyError 文案受影响
print(repr(ValueError(10 ** 100)))
print(repr(ValueError(-(10 ** 100))))
print(repr(ValueError(10 ** 20, "msg")))
print(repr(TypeError(2 ** 64)))

# KeyError 的大数键文案
try:
    d = {}
    d[10 ** 100]
except KeyError as e:
    print(str(e))

try:
    d = {1: 1}
    d[-(2 ** 64)]
except KeyError as e:
    print(str(e))

# 大数键在容器 repr 中还原原始形态
print({10 ** 20: 1})
print(list({10 ** 20: 1}))
print({-(2 ** 64): "a"})

# 小整数保持原样 (边界)
print(repr(ValueError(42)))
print(repr(ValueError(-1)))
