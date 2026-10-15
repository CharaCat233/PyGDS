# 职责: 排序/反转/枚举/配对内置函数
# 比对: same_output


# sorted
print(sorted([3, 1, 2]))  # [1, 2, 3]
print(sorted([3, 1, 2], reverse=True))  # [3, 2, 1]
print(sorted(["bb", "a", "ccc"], key=len))  # ['a', 'bb', 'ccc']

# reversed
print(list(reversed([1, 2, 3])))  # [3, 2, 1]
print(list(reversed("abc")))  # ['c', 'b', 'a']

# enumerate
print(list(enumerate(["a", "b", "c"])))  # [(0, 'a'), (1, 'b'), (2, 'c')]
print(list(enumerate(["a", "b"], start=5)))  # [(5, 'a'), (6, 'b')]

# zip
print(list(zip([1, 2, 3], ["a", "b", "c"])))  # [(1, 'a'), (2, 'b'), (3, 'c')]
print(list(zip([1, 2], ["a", "b", "c"])))  # [(1, 'a'), (2, 'b')]
print(list(zip([1, 2, 3], ["a", "b"])))  # [(1, 'a'), (2, 'b')]



# sorted / list.sort 稳定性 (CPython Timsort, PyGDS 稳定归并)
def _stable(res):
    last_k = None
    last_i = -1
    for k, i in res:
        if k == last_k and i < last_i:
            return False
        last_k = k
        last_i = i
    return True


_data = [(i % 7, i) for i in range(200)]
print("sorted_stable", _stable(sorted(_data, key=lambda x: x[0])))
print("sorted_rev_stable", _stable(sorted(_data, key=lambda x: x[0], reverse=True)))
_lst = _data[:]
_lst.sort(key=lambda x: x[0])
print("list_sort_stable", _stable(_lst))
print("sorted_plain", sorted([3, 1, 2]))
