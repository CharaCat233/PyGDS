# 职责: list/tuple 字典序与 sort key
# 比对: same_output


print((1,) < (3,))
print([1] < [3])
print((1, 2) < (1, 3))
print([2] > [1, 99])
print([1, 2] <= [1, 2])
print([1, 2] >= [1, 2])
print((1, "a") < (1, "b"))
print([True, 2] < [1, 3])
print((1,) < (1, 0))

print(sorted([(2, "b"), (1, "a")]))
print(sorted([[2, "b"], [1, "a"]]))
print(sorted([(3,), (1,), (2,)]))
print(max([(2, "b"), (1, "a")]))
print(min([(2, "b"), (1, "a")]))

print(max([1, 2, 3], key=lambda x: -x))
print(min([1, 2, 3], key=lambda x: -x))
print(max("ba", "ab", key=lambda s: s[1]))
print(max([(1, 9), (2, 0)], key=lambda t: t[0]))

try:
    sorted([1, "a"])
except TypeError:
    print("TE1")
try:
    min([1, "a"])
except TypeError:
    print("TE2")
l = [1, "a"]
try:
    l.sort()
except TypeError:
    print("TE3")

# 跨容器类型相等: list 与 tuple/set/dict 互比恒不相等
print([1] == (1,), [1] != (1,))
print((1,) == [1], {} == [], set() == [])
print([1, 2] == [1, 2], (1, 2) == (1, 2))
print({1} == [1], {1} == (1,), frozenset({1}) == {1})

# 序列比较吞掉元素比较错误 (此前静默 False, 应报 TypeError)
try:
    print([1] < ["a"])
except TypeError as e:
    print("TE:", str(e))

try:
    print([[1]] < [["a"]])
except TypeError as e:
    print("TE-nested:", str(e))

try:
    print((1,) < ("a",))
except TypeError as e:
    print("TE-tuple:", str(e))

try:
    print([1] <= ["a"])
except TypeError as e:
    print("TE-le:", str(e))

# set 与非集合序比较 (此前静默 False)
try:
    print({1} < [1])
except TypeError as e:
    print("TE-set:", str(e))

# 字典键/项视图参与集合比较 (此前无视图分支恒 False)
print({1} <= {1: 0}.keys())
print({1, 2} >= {1: 0}.keys())
print({1} < {1: 0, 2: 0}.keys())
print({1: 0, 2: 0}.keys() <= {1, 2})
print({1} == {1: 0}.keys())
