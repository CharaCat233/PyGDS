# Error: 元组 except 不匹配

tuple_not_caught = False
try:
    try:
        raise KeyError("no match")
    except (TypeError, ValueError):
        tuple_not_caught = True
except KeyError:
    tuple_not_caught = False
print(tuple_not_caught)
