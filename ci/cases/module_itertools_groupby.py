# 职责: groupby 惰性 grouper 一次性与游标共享
# 比对: same_output

# groupby 的惰性 grouper (P2-24)
from itertools import groupby
for k, g in groupby("aabbc"):
    print(k, list(g))
# 外层推进后, 旧 grouper 立即耗尽且不消费后续组的数据
it = groupby("aabbc")
k1, g1 = next(it)
k2, g2 = next(it)
print(k1, k2)
print(list(g1))
print(list(g2))
# grouper 为一次性迭代器, 重复迭代得空
print(list(g1))
try:
    print(k1, next(g1))
except StopIteration:
    print("stop")
print(type(it).__name__)
print(type(g1).__name__)
print(list(groupby([])))
print(list(groupby([], key=str)))
data = [1, 3, 2, 4, 5, 7]
for k, g in groupby(data, key=lambda x: x % 2):
    print(k, list(g))
print([k for k, _ in groupby("aaabb")])
print([list(g) for _, g in groupby("aaabb")])
# 源为迭代器时 grouper 与外层共享游标
src = iter([1, 1, 2])
it2 = groupby(src)
k, g = next(it2)
print(k, next(g), list(g))
print(iter(it2) is it2)
# 先收集全部 (键, grouper) 再回溯迭代: 源已耗尽, 全为空
pairs = list(groupby("aabb"))
print([list(g) for _, g in pairs])
print("done")
