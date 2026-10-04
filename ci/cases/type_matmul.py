# 职责: @ 矩阵乘运算符 (P2-16, 语法层): 内建类型 TypeError 文案、用户 __matmul__ / __rmatmul__、与 * 的同优先级、@= 增强赋值
# 比对: same_output

# 内建数值类型未实现 __matmul__
try:
    print(1 @ 2)
except TypeError as e:
    print("mm:", e)
try:
    print("a" @ "b")
except TypeError as e:
    print("mm2:", e)


# 用户类 __matmul__
class Vec:
    def __init__(self, v):
        self.v = v

    def __matmul__(self, o):
        return sum(a * b for a, b in zip(self.v, o.v))


print(Vec([1, 2]) @ Vec([3, 4]))
print(Vec([1, 2, 3]) @ Vec([4, 5, 6]))

# 反射: 左侧无 __matmul__ 时走右侧 __rmatmul__


class Scalar:
    def __init__(self, v):
        self.v = v

    def __rmatmul__(self, o):
        return ("r", o, self.v)


print(1 @ Scalar(9))

# 同类型仅定义 __rmatmul__: CPython 不走反射 (既定差异 P2-57, 不做双端断言)

# 与 * 同优先级 (左结合): (a @ b) * 2 与 a @ (b * 2) 形态区分


class Box:
    def __init__(self, tag):
        self.tag = tag

    def __matmul__(self, o):
        return self.tag + o.tag


b1 = Box("a")
b2 = Box("b")
print(b1 @ b2)
print(b1 @ b2 + "!")
print("x" + (b1 @ b2))

# @= 增强赋值: 用户类走 __matmul__ (无 __imatmul__ 时回退)


class Acc:
    def __init__(self):
        self.total = 0

    def __matmul__(self, o):
        self.total += o
        return self


acc = Acc()
acc @= 3
acc @= 4
print(acc.total)

# 内建类型的 @= 报错
try:
    n = 1
    n @= 2
except TypeError as e:
    print("aug:", e)

# operator.matmul
import operator
try:
    print(operator.matmul(1, 2))
except TypeError as e:
    print("op:", e)
print("done")
