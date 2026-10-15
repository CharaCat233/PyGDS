# 职责: 用户类实现长度/成员/迭代协议
# 比对: same_output


import math


# __len__
class MyCollection:
    def __init__(self, items):
        self.items = items

    def __len__(self):
        return len(self.items)

    def __contains__(self, item):
        return item in self.items

    def __iter__(self):
        return iter(self.items)


mc = MyCollection([1, 2, 3, 4, 5])
print(len(mc))  # 5
print(3 in mc)  # True
print(6 in mc)  # False

for item in mc:
    print(item, end=" ")  # 1 2 3 4 5
print()

# 转列表
print(list(mc))  # [1, 2, 3, 4, 5]



# __format__ 协议生效 + 返回值必须 str
class F11:
    def __format__(self, spec):
        return "<F:" + spec + ">"


print(format(F11(), "abc"))
print(format(F11(), ""))


class F11b:
    def __format__(self, spec):
        return 5


try:
    format(F11b(), "")
except TypeError as e:
    print("TE-fmt:", str(e))


class NoFmt11:
    pass


print(format(NoFmt11(), ""))
try:
    format(NoFmt11(), "abc")
except TypeError as e:
    print("TE-fmt2:", str(e))


# __round__/__floor__/__ceil__/__trunc__ 数字协议
class R28:
    def __round__(self, n=None):
        return ("R", n)


print(round(R28()))
print(round(R28(), 2))


class F28:
    def __floor__(self):
        return 7


class C28:
    def __ceil__(self):
        return 8


class T28:
    def __trunc__(self):
        return 9


print(math.floor(F28()))
print(math.ceil(C28()))
print(math.trunc(T28()))
