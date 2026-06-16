# Error: 元组 except 语法

tuple_caught = False
try:
    raise ValueError("tuple test")
except (TypeError, ValueError):
    tuple_caught = True
print(tuple_caught)
