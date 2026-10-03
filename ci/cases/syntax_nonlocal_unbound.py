# 职责: nonlocal 无绑定错误文案 (CPython 编译期, PyGDS 调用时运行期, 消息按 CPython 对齐)
# 比对: same_error

def f():
    nonlocal x
    x = 1


f()
