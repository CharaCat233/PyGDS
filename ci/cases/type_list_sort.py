# 职责: sort 的 key/reverse 与 sorted
# 比对: same_output


# 基本 sort
a = [3, 1, 2]
a.sort()
print(a)  # [1, 2, 3]

# reverse
b = [3, 1, 2]
b.sort(reverse=True)
print(b)  # [3, 2, 1]

# key 参数 (lambda)
c = ["bb", "a", "ccc"]
c.sort(key=len)
print(c)  # ['a', 'bb', 'ccc']


# key 参数 (自定义函数)
def last_char(s):
    return s[-1]


d = ["ab", "ca", "bc"]
d.sort(key=last_char)
print(d)  # ['ab', 'bc', 'ca']

# sorted (返回新列表)
e = [3, 1, 2]
f = sorted(e)
print(e)  # [3, 1, 2] (原列表不变)
print(f)  # [1, 2, 3] (新列表)


# sorted/list.sort 稳定性 (此前宿主 sort_custom 不稳定)
# 等价元素保持原相对顺序 (CPython Timsort 稳定)
data = [(i % 2, (i * 104729) % 512) for i in range(512)]
s = sorted(data, key=lambda x: x[0])
firsts = [i for i, x in enumerate(s) if x[0] == 0]
print(all(firsts[i] < firsts[i + 1] for i in range(len(firsts) - 1)))

data2 = [(i % 3, i) for i in range(300)]
data2.sort(key=lambda x: x[0])
groups = [[x[1] for x in data2 if x[0] == g] for g in range(3)]
print(
    groups[0] == sorted(groups[0]),
    groups[1] == sorted(groups[1]),
    groups[2] == sorted(groups[2]),
)

# reverse=True 的稳定性 (按更大者在前, 等价元素保持原序)
data3 = [(1, "a"), (1, "b"), (0, "c"), (0, "d")]
print(sorted(data3, key=lambda x: x[0], reverse=True))

# 无 key 排序的稳定性
data4 = [3, 1, 2, 1, 3, 2]
data4.sort()
print(data4)

# sorted 关键字实参校验 (reverse 真值化 / key 可调用校验)
print(sorted([3, 1, 2], reverse=1))
print(sorted([3, 1, 2], reverse=0))
print(sorted([3, 1, 2], reverse=[]))
try:
    sorted([1, 2], key=5)
except TypeError as e:
    print("TE-sorted-key:", e)
