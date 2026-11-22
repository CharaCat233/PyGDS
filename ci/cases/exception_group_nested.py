# 职责: 嵌套异常组的 except* 提取与 subgroup/split 递归拆分
# 比对: same_output


def raise_nested():
    raise ExceptionGroup("nest", [ExceptionGroup("in", [ValueError("d"), KeyError("k")]), TypeError("e")])


try:
    raise_nested()
except* ValueError as eg:
    print("v:", repr(eg))
except* KeyError as eg:
    print("k:", repr(eg))
except* TypeError as eg:
    print("t:", repr(eg))

g = ExceptionGroup("g", [ExceptionGroup("sub", [ValueError("v"), KeyError("k")]), TypeError("t")])
print("subgroup:", repr(g.subgroup(ValueError)))
print("subgroup-none:", g.subgroup(ZeroDivisionError))
m, r = g.split(TypeError)
print("split:", repr(m), "|", repr(r))
m2, r2 = g.split(ZeroDivisionError)
print("split-all:", repr(r2))
