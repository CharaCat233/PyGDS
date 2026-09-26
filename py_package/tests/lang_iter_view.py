# Feature: dict.items() 视图对象与 defaultdict 的 iter() 类型名

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
