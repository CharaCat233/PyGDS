# 职责: iter 各容器类型名、活动视图与耗尽
# 比对: same_output

from itertools import count, cycle, groupby, islice, repeat, tee

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

# next() 只接受迭代器对象: 可迭代但非迭代器报 TypeError
_show_next("next_list", lambda: next([1, 2]))
_show_next("next_str", lambda: next("abc"))
_show_next("next_tuple", lambda: next((1, 2)))
_show_next("next_range", lambda: next(range(3)))
_show_next("next_dict", lambda: next({1: "a"}))
_show_next("next_set", lambda: next({1, 2}))
_show_next("next_keys", lambda: next({1: "a"}.keys()))
_show_next("next_items", lambda: next({1: "a"}.items()))

# iter() 通用回退的快照形态仍是迭代器 (next 可消费, 不消费裸列表)
_show_next("next_snap", lambda: next(iter({1: "a"})))
_show_next("next_snap2", lambda: next(iter("abc"), "dflt"))

# 内建惰性消费器与 itertools 形态是一等迭代器
_show_next("next_map", lambda: next(map(lambda x: x * 2, [3, 4])))
_show_next("next_zip", lambda: next(zip([1], [2])))
_show_next("next_enum", lambda: next(enumerate("ab")))
_show_next("next_filter", lambda: next(filter(None, [0, 5])))
_show_next("next_islice", lambda: next(islice(count(), 1, 3)))
_show_next("next_tee", lambda: next(tee([9, 8])[0]))
_show_next("next_count", lambda: next(count(5)))
_show_next("next_cycle", lambda: next(cycle([1, 2])))
_show_next("next_repeat", lambda: next(repeat(7, 3)))
_show_next("next_rev_list", lambda: next(reversed([1, 2, 3])))
_show_next("next_rev_range", lambda: next(reversed(range(4))))


def _gb():
    k, g = next(groupby("aab"))
    return k, next(g)


_show_next("next_groupby", _gb)


# 用户迭代器 (对象自身实现 __next__, __iter__ 返回 self) 仍可 next() 消费
class It65:
    def __init__(self):
        self.i = 0

    def __iter__(self):
        return self

    def __next__(self):
        self.i += 1
        if self.i > 2:
            raise StopIteration
        return self.i


def _u1():
    it = It65()
    return next(it)


def _u2():
    it = It65()
    next(it)
    return next(it)


def _u3():
    it = It65()
    next(it)
    next(it)
    return next(it, "end")


_show_next("next_user1", _u1)
_show_next("next_user2", _u2)
_show_next("next_user3", _u3)


# 用户可迭代但非迭代器 (仅 __iter__) 报 TypeError
class OnlyIter:
    def __iter__(self):
        return iter([1, 2])


_show_next("next_onlyiter", lambda: next(OnlyIter()))
_show_next("next_onlyiter2", lambda: next(iter(OnlyIter())))


# 异步生成器只有 __anext__ 无 __next__
async def _agen():
    yield 1


def _na():
    ag = _agen()
    return next(ag)


_show_next("next_agen", _na)
