# Error: 元组 except 多类型

tuple_caught2 = False
try:
    raise TypeError("tuple test 2")
except (ValueError, RuntimeError, TypeError):
    tuple_caught2 = True
print(tuple_caught2)
