# 职责: sum() 的 start= 关键字实参与类型校验
# 比对: same_output

# sum() 此前完全忽略 start= 关键字实参
print(sum([1, 2], start=5))
print(sum([1, 2, 3], start=10))
print(sum([], start=7))
print(sum([1.5, 2.5], start=1))
print(sum(range(4), start=100))

# 位置实参与关键字等价
print(sum([1, 2], 5) == sum([1, 2], start=5))

# 字符串起始值拒绝 (CPython: 提示用 join)
try:
    print(sum(["a", "b"], ""))
except TypeError as e:
    print("TE", str(e))

try:
    print(sum(["a"], start=""))
except TypeError as e:
    print("TE", str(e))

# 类型错误传播 (sum(["a"]) 报 TypeError, 此前静默 None)
try:
    print(sum(["a"]))
except TypeError as e:
    print("TE", str(e))

try:
    print(sum([1, "x"]))
except TypeError as e:
    print("TE", str(e))

# 正常路径
print(sum([1, 2, 3]))
print(sum([]))
print(sum([[1], [2]], []))
