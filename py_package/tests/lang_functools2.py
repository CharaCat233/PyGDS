# functools.cmp_to_key 测试

from functools import cmp_to_key


def cmp_desc(a, b):
    return b - a


def cmp_len(a, b):
    return len(a) - len(b)


def cmp_str(a, b):
    if a < b:
        return -1
    if a > b:
        return 1
    return 0


# 旧式比较函数用于 sorted(key=)
print(sorted([3, 1, 4, 1, 5], key=cmp_to_key(cmp_desc)))     # [5, 4, 3, 1, 1]
print(sorted(["bb", "a", "ccc"], key=cmp_to_key(cmp_len)))   # ['a', 'bb', 'ccc']
print(sorted(["banana", "apple", "cherry"], key=cmp_to_key(cmp_str)))

# lambda 形式
print(sorted([1, 2, 3], key=cmp_to_key(lambda a, b: b - a)))   # [3, 2, 1]
print(sorted([1, 2, 3], key=cmp_to_key(lambda a, b: a - b)))   # [1, 2, 3]

# 与 reverse 组合
print(sorted([1, 2, 3], key=cmp_to_key(lambda a, b: a - b), reverse=True))

# 元组按第二列排序
pairs = [(1, 3), (2, 1), (3, 2)]
print(sorted(pairs, key=cmp_to_key(lambda a, b: a[1] - b[1])))

# list.sort 同样支持
lst = [2, 5, 1, 4]
lst.sort(key=cmp_to_key(lambda a, b: a - b))
print(lst)      # [1, 2, 4, 5]

# 返回对象可调用
print(callable(cmp_to_key(lambda a, b: 0)))    # True
print(type(cmp_to_key(lambda a, b: 0)))        # <class 'functools.KeyWrapper'>
print(type(cmp_to_key(lambda a, b: 0)(5)))     # <class 'functools.KeyWrapper'>
print(cmp_to_key(lambda a, b: 0))              # <functools.KeyWrapper object>

# 与普通 key 函数结果一致
def key_neg(x):
    return -x


print(sorted([3, 1, 2], key=cmp_to_key(lambda a, b: b - a)) == sorted([3, 1, 2], key=key_neg))

print("done")
