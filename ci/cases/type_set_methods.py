# 职责: 集合方法接受任意可迭代与原地更新族
# 比对: same_output


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

# set.union/intersection/difference 多实参 (此前只合并首个)
print(sorted(set.union({1}, {2}, {3})))
print(sorted({1, 2}.union({2, 3}, {3, 4})))
print(sorted({1, 2, 3}.intersection({2, 3}, {2})))
print(sorted({1, 2, 3}.difference({2}, {3})))
print(sorted({1, 2}.union([3], [4])))
print(sorted({1, 2, 3, 4}.intersection([2, 3], [3, 4])))
print(sorted({1, 2, 3, 4}.difference([2], [3])))
# 混合类型 (str 元素) 的 union: 用 len 与成员判定断言 (集合打印顺序双端不保证)
m = {1, 2}.union([3], "ab")
print(len(m), 1 in m, "a" in m, "b" in m, 3 in m)
print(len({1, 2}.union("ab")))

# 相等元素保留首个插入对象 (CPython 首元素胜出, 此前末元素覆盖)
print(list({1, True}))
print(list({1, 1.0}))
print(list({1.0, True}))
print(list({True, 1.0}))
print(list({1 + 0j, 1}))
s78 = set()
s78.add(1)
s78.add(True)
print(list(s78))
s78.update([True, 1.0])
print(list(s78))
print({1, True} == {True})
s78.discard(1.0)
print(list(s78))

# 迭代期间变更集合尺寸报 RuntimeError (对齐 dict 键迭代器)
try:
    s91 = {1, 2, 3}
    for x in s91:
        s91.add(99)
except RuntimeError as e:
    print("RE:", e)
try:
    s91b = {1, 2, 3}
    for x in s91b:
        s91b.remove(2)
except RuntimeError as e:
    print("RE2:", e)
# 迭代期间不改尺寸 (值替换不存在; 先收集再改) 正常
s91c = {1, 2, 3}
out91 = []
for x in s91c:
    out91.append(x)
print(sorted(out91))
s91c.add(4)
print(sorted(s91c))

# 多余位置实参: CPython 参数数文案
def _arg_exc(label, fn):
    try:
        print(label, repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, str(e))


_arg_exc("add-2", lambda: {1}.add(2, 3))
_arg_exc("discard-2", lambda: {1}.discard(1, 2))
_arg_exc("remove-2", lambda: {1}.remove(1, 2))
