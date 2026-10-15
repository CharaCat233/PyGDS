# 职责: range 大数长度 ceil 尾差、快路径 len 回绕、True in range
# 比对: same_output

# len(range(大数)) 此前用 floor 少一个元素 (长度 = (|diff|+1)-1 化简为 |diff|)
print(len(range(10 ** 20, 10 ** 20 + 10, 3)))
print(len(range(10 ** 20, 10 ** 20 + 9, 3)))
print(len(range(10 ** 20, 10 ** 20 + 3, 3)))
print(len(range(10 ** 20, 10 ** 20 + 1, 3)))
print(len(list(range(10 ** 20, 10 ** 20 + 10, 3))))
print(len(list(range(10 ** 20, 10 ** 20 + 9, 3))))
# 超 sys.maxsize 的长度按 CPython 报 OverflowError (len 须装进索引位宽)
try:
    print(len(range(0, 10 ** 20, 7)))
except OverflowError as e:
    print("OE:", str(e))
try:
    print(len(range(-(10 ** 20), 0, 7)))
except OverflowError as e:
    print("OE:", str(e))

# 大数范围元素 (物化与下标)
r = range(10 ** 20, 10 ** 20 + 10, 3)
print(list(r))
print(r[0])
print(r[3])

# range 快路径 stop-start 回绕 int64 时 len 为负数
# 改为经大数端点精确计算
print(len(range(-2 ** 62, 2 ** 62, 2 ** 61)))
print(range(-2 ** 62, 2 ** 62, 2 ** 61)[0])
print(len(range(-2 ** 62, 2 ** 62, 2 ** 61)))
print(list(range(-2 ** 62, 2 ** 62, 2 ** 61)))

# 大跨度正步长 (stop-start 超 int64 正域)
print(len(range(-(2 ** 62), 2 ** 62, 2 ** 61)))
print(len(range(-(2 ** 62), 2 ** 62, 2 ** 62)))
print(len(range(-(2 ** 63), 2 ** 63, 2 ** 62)))

# True in range (bool 为 int 子类)
print(True in range(2))
print(False in range(2))
print(False in range(0, 1))
print(True in range(1, 5))
print(False in range(5, 1))
print(True in range(10, 0, -1))
print(True not in range(2, 5, 2))

# 非整数成员判定 (CPython: 返回 False 而非报错)
print(1.5 in range(2))
print("1" in range(2))
print(1.0 in range(2))
print(2.0 in range(3))


# range 相等按元素序列 (长度相同 + 非空时起点/步长相同)
print(range(0, 5, 2) == range(0, 6, 2))
print(range(5) == range(0, 5, 1))
print(range(0, 4, 2) == range(0, 5, 2))
print(range(0, 5, 2) == range(1, 5, 2))
print(range(3) == range(0, 1, 1))
# __index__ 协议在 range 构造生效
class Index22:
    def __index__(self):
        return 3
print(list(range(Index22())))
print(list(range(1, Index22(), 2)))
try:
    list(range(3.5))
except TypeError as e:
    print("TE:", str(e))
