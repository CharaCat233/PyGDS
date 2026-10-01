# 职责: 三类型元组 except 命中 TypeError
# 比对: same_output


tuple_caught2 = False
try:
    raise TypeError("tuple test 2")
except (ValueError, RuntimeError, TypeError):
    tuple_caught2 = True
print(tuple_caught2)
