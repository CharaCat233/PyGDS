# 职责: abs/min/max/sum 内置函数各形态
# 比对: same_output


print(abs(-5))               # 5
print(abs(5))                # 5
print(abs(-3.14))            # 3.14
print(abs(0))                # 0

print(min(1, 2, 3))          # 1
print(min(3, 2, 1))          # 1
print(min([5, 3, 9]))        # 3
print(max(1, 2, 3))          # 3
print(max(3, 2, 1))          # 3
print(max([5, 3, 9]))        # 9

print(sum([1, 2, 3]))        # 6
print(sum([1, 2, 3], 10))    # 16
print(sum([]))               # 0
print(sum([], 5))            # 5

# 错误路径: 不可求 abs 的类型与空序列
try:
    abs("a")
except TypeError as e:
    print("TE:", e)
try:
    min([])
except ValueError as e:
    print("VE:", e)
try:
    max()
except TypeError as e:
    print("TE2:", e)
try:
    min(1)
except TypeError as e:
    print("TE3:", e)

print("done")