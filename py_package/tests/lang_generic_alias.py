# 泛性别名 list[int] 等 (PEP 585, alpha.4, P1-64)
print(list[int] is list[int])
print(list[int] == list[int], list[int] == list[str])
ga = list[int]
print(ga.__origin__ is list, ga.__args__)
print(dict[str, int], tuple[int, ...], set[int], frozenset[int], type[int])
print(list[int](), dict[str, int](), tuple[int, str]())
print(list["a"], list[1.5])
print(dict[str, int].__args__)
print(list[int].__origin__.__name__)
print(hash(list[int]) == hash(list[int]))
print(list[int] != list[str], list[int] != 5)

# 用户类 __class_getitem__ 协议
class Box:
    def __class_getitem__(cls, item):
        return (cls.__name__, item)

print(Box[int], Box["x"])
