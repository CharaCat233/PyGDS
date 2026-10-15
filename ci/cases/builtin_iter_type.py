# 职责: iter 各容器类型名、活动视图与耗尽
# 比对: same_output


print(type(iter([1])).__name__)
print(type(iter("ab")).__name__)
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
d = {"a": 1}
it3 = iter(d)
print(list(it3))
it4 = iter("ab")
print(next(it4))
print(repr(iter((1,))))


# reversed 协议支持 (__reversed__ / __len__+__getitem__)
class Rev:
    def __reversed__(self):
        return [3, 2, 1]


print(list(reversed(Rev())))


class Seq:
    def __init__(self):
        self.data = [10, 20, 30]

    def __len__(self):
        return len(self.data)

    def __getitem__(self, i):
        return self.data[i]


print(list(reversed(Seq())))
print(list(reversed("abc")))
try:
    reversed({1, 2})
except TypeError as e:
    print("TE-set:", e)
try:
    reversed(5)
except TypeError as e:
    print("TE-int:", e)


# next() 非迭代器实参补类型名 (CPython 'int' object is not an iterator)
def _show_next(label, fn):
    try:
        print(label, "OK", fn())
    except Exception as e:
        print(label, type(e).__name__, str(e))


_show_next("next_int", lambda: next(5))
_show_next("next_none", lambda: next(None))
_show_next("next_iter_ok", lambda: next(iter([7, 8])))
_show_next("next_default", lambda: next(iter([]), 99))
