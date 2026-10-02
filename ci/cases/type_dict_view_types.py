# 职责: dict 视图类型名、repr 与相等比较
# 比对: same_output


import collections

d = {'a': 1, 'b': 2}
print(type(d.items()).__name__)
print(len(d.items()))
print(list(d.items()))
print(('a', 1) in d.items())
print(d.items())
dd = collections.defaultdict(int)
print(type(iter(dd)).__name__)
print(type(iter(d.items())).__name__)
print(d.values())
print(type(d.values()).__name__)
d1 = {'a': 1}
d2 = {'a': 1}
print(d1.items() == d2.items())

# 视图与 set 的集合运算 (P1-69): keys/items 视图是 set-like, values 视图不是
d2 = {"a": 1, "b": 2, "c": 3}
ks = d2.keys()
print(sorted(ks & {"a", "b"}))           # ['a', 'b']
print(sorted(ks - {"a"}))                # ['b', 'c']
print(sorted(ks | {"z"}))                # ['a', 'b', 'c', 'z']
print(sorted({"a"} & ks))                # ['a'] (set 左操作数)
print(sorted(d2.items() & {("a", 1)}))   # [('a', 1)]
print(sorted(frozenset({"a"}) & ks))     # ['a']
try:
    print(sorted({1} | {"q"} & d2.values()))
except TypeError:
    print("TE-values")                   # values 视图非 set-like
try:
    print(sorted(d2.values() & {1, 2}))
except TypeError:
    print("TE-values2")
try:
    print(ks & 1)
except TypeError:
    print("TE-int")
