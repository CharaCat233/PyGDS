# Feature: 集合方法接受任意可迭代 + 原地更新族

st = {1, 2}
st.update([3])
print(sorted(st))
st.intersection_update({2, 3})
print(sorted(st))
st.difference_update([3])
print(sorted(st))
st.symmetric_difference_update([1, 4])
print(sorted(st))
print({1, 2}.union([9]))
print({1}.issubset([1, 2]))
print({1, 2}.issuperset([1]))
print({1}.isdisjoint([2]))
print(sorted({1, 2}.intersection([1, 3])))
print(sorted({1}.difference([2])))
print('done')
