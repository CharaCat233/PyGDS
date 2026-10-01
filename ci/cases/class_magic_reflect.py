# 职责: __radd__ 等反射运算与优先级
# 比对: same_output



class Money:
    def __init__(self, amount):
        self.amount = amount

    def __radd__(self, other):
        return Money(other + self.amount)

    def __rsub__(self, other):
        return Money(other - self.amount)

    def __rmul__(self, other):
        return Money(other * self.amount)

    def __repr__(self):
        return "Money(" + str(self.amount) + ")"

    def __eq__(self, other):
        if isinstance(other, Money):
            return self.amount == other.amount
        if isinstance(other, int):
            return self.amount == other
        return self.amount == other


print(10 + Money(5))
print(10 - Money(3))
print(3 * Money(4))
print(10 + Money(5) == Money(15))
print(1 == Money(1), 2 == Money(1))

# 用户类两侧均定义 __add__ 时左侧优先
class Both:
    def __add__(self, o):
        return "left-add"

    def __radd__(self, o):
        return "right-radd"


print(Both() + 1)
print(1 + Both())

# 反射方法内抛出的异常照常传播
class Boom:
    def __radd__(self, other):
        raise ValueError("boom")


try:
    1 + Boom()
except ValueError as e:
    print("reflected raise:", e)

# 内建之间的运算不受影响
print(1 + 2, "a" + "b", [1] + [2])
