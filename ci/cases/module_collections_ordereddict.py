# duty: collections.OrderedDict 的构造/顺序敏感相等/move_to_end/popitem
# 比对: same_output
from collections import OrderedDict

od = OrderedDict([("a", 1), ("b", 2)])
print(od)
print(OrderedDict(a=1, b=2))
od.move_to_end("a")
print(od)
od.move_to_end("a", last=False)
print(od)
print(od.popitem())
od2 = OrderedDict([("a", 1), ("b", 2)])
print(od2.popitem(last=False))
try:
    OrderedDict().popitem()
except KeyError as err:
    print("KE:", err)
print(OrderedDict([("a", 1)]) == OrderedDict([("a", 1)]))
print(OrderedDict([("a", 1), ("b", 2)]) == OrderedDict([("b", 2), ("a", 1)]))
print(OrderedDict([("a", 1), ("b", 2)]) == {"a": 1, "b": 2})
print(list(od2.keys()), od2.get("x", 5))
od2["b"] = 9
print(od2)
print(od2.copy())
del od2["b"]
print(od2)
print(type(od2).__name__)
try:
    od2.move_to_end("zzz")
except KeyError as err:
    print("KM:", err)
