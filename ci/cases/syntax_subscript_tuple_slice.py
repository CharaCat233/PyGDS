# 职责: 下标中 "元组 + 切片" 混合形态解析
# 比对: same_output


class M:
    def __getitem__(self, k):
        return repr(k)

    def __setitem__(self, k, v):
        print("set:", k, v)


# 元组 + 切片混合下标键
print(M()[0, 1:3])  # (0, slice(1, 3, None))
print(M()[:, 1])  # (slice(None, None, None), 1)
print(M()[0:1, 2])  # (slice(0, 1, None), 2)
print(M()[0, 1])  # (0, 1)
print(M()[1:3])  # slice(1, 3, None)
print(M()[:])  # slice(None, None, None)
print(M()[::2])  # slice(None, None, 2)
print(M()[1,])  # (1,)

# * 解包下标
a = [1, 2]
print(M()[*a])  # (1, 2)
print(M()[*a, 1])  # (1, 2, 1)

# 下标赋值目标的元组+切片混合
m = M()
m[0, 1:3] = 5
m[:, 1] = 6
m[0:1, 2] = 7

# 列表以元组下标索引报 TypeError (异常类一致)
try:
    [1, 2, 3][0, 1:3]
except TypeError as e:
    print(type(e).__name__)

# 既有切片赋值不受影响
l = [1, 2, 3, 4]
l[0:2] = [9, 9]
print(l)
