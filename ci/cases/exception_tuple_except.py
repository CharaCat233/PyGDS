# 职责: except 元组多类型命中其一
# 比对: same_output


tuple_caught = False
try:
    raise ValueError("tuple test")
except (TypeError, ValueError):
    tuple_caught = True
print(tuple_caught)
