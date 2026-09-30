# 内建容器 dunder 协议方法 (alpha.5, P1-67)
print([1, 2].__len__(), (1,).__len__(), {"a": 1}.__len__())
print("ab".__len__(), b"ab".__len__(), range(5).__len__())
print({1}.__len__(), frozenset([1]).__len__())
print(list("ab".__iter__()), list(range(3).__iter__()))
d = {"x": 1}
d.__delitem__("x")
print(d)
l2 = [1, 2, 3]
l2.__delitem__(1)
print(l2)
try:
    (1,).__delitem__(0)
except AttributeError as e:
    print("tuple:", "no attribute" in str(e))
