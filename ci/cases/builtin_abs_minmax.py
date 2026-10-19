# 职责: abs/min/max/sum 内置函数各形态
# 比对: same_output


print(abs(-5))  # 5
print(abs(5))  # 5
print(abs(-3.14))  # 3.14
print(abs(0))  # 0

print(min(1, 2, 3))  # 1
print(min(3, 2, 1))  # 1
print(min([5, 3, 9]))  # 3
print(max(1, 2, 3))  # 3
print(max(3, 2, 1))  # 3
print(max([5, 3, 9]))  # 9

print(sum([1, 2, 3]))  # 6
print(sum([1, 2, 3], 10))  # 16
print(sum([]))  # 0
print(sum([], 5))  # 5

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

# sum 类型错误传播 (此前静默返回 None 或 "ab")
# CPython: 不可加类型报 unsupported operand, 字符串起始值拒绝
try:
    sum(["a"])
except TypeError as e:
    print("TE-sum1:", e)
try:
    sum(["a", "b"], "")
except TypeError as e:
    print("TE-sum2:", e)
try:
    sum([], "")
except TypeError as e:
    print("TE-sum3:", e)
try:
    sum([1, "a"])
except TypeError as e:
    print("TE-sum4:", e)
try:
    sum([[1], [2]])
except TypeError as e:
    print("TE-sum5:", e)
print(sum([1, 2], 5))

# abs 接受 bool (bool 是 int 子类)
print(abs(True))
print(abs(False))

# 多余位置实参: CPython 参数数文案
def _arg_exc(label, fn):
    try:
        print(label, repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, str(e))


_arg_exc("abs-2", lambda: abs(1, 2))
_arg_exc("sum-3", lambda: sum([1], 1, 1))

# key=None 哨兵等价未提供 (CPython 语义, 非 None 不可调用仍报 TypeError)
_arg_exc("mn-key-none", lambda: min([2, 1], key=None))
_arg_exc("mx-key-none", lambda: max([2, 1], key=None))
_arg_exc("mn-key-none-default", lambda: min([], key=None, default="d"))
_arg_exc("mn-key-none-int", lambda: min(3, 1, 2, key=None))
_arg_exc("mn-key-real", lambda: min(["bb", "a"], key=len))
