# Feature: iter() 返回真迭代器 (活动视图, 类型名与 CPython 一致)

print(type(iter([1])).__name__)
print(type(iter('ab')).__name__)
print(type(iter((1,))).__name__)
print(type(iter(range(2))).__name__)

lst = [1, 2]
it = iter(lst)
lst.append(3)
print(list(it))

it2 = iter([1, 2, 3])
print(next(it2))
print(next(it2))
print(list(it2))
print(list(it2))

print(repr(iter([1])))
d = {'a': 1}
it3 = iter(d)
print(list(it3))
it4 = iter('ab')
print(next(it4))
print(repr(iter((1,))))
